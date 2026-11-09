module Trips
  class ItemReplacer
    MEAL_SLOTS = %w[breakfast lunch dinner].freeze

    def initialize(
      recommender: Recommendations::Rank.new(provider: Recommendations::CacheFirstProvider.new),
      dining_provider: Dining::ProviderFactory.build,
      route_annotator: RouteAnnotator.new
    )
      @recommender = recommender
      @dining_provider = dining_provider
      @route_annotator = route_annotator
    end

    def call(item:, language: "en")
      trip = item.trip_day.trip
      attributes = if MEAL_SLOTS.include?(item.slot)
        meal_attributes(item, trip, language)
      else
        activity_attributes(item, trip, language)
      end

      baseline = item.metadata.slice("rhythm_starts_at", "rhythm_ends_at")
      attributes[:metadata] = baseline.merge(attributes.fetch(:metadata, {}))
      item.with_lock { item.update!(attributes.merge(status: "suggested")) }
      @route_annotator.reset!
      @route_annotator.call(trip_day: item.trip_day, trip:, language:)
      trip.reload
    end

    private

    def meal_attributes(item, trip, language)
      used = trip_items(trip).where.not(external_id: nil).pluck(:provider, :external_id).to_set
      venue = @dining_provider.search(
        location: trip.location,
        meal: item.slot,
        radius_km: trip.max_distance_km.to_f,
        language:,
        preferences: trip.preferences
      ).find do |candidate|
        candidate.distance_km.to_f <= trip.max_distance_km.to_f &&
          used.exclude?([ candidate.provider, candidate.external_id ])
      end
      raise NoAlternativeError, "No different venue is available for this meal" unless venue

      {
        recommendation: nil,
        kind: "meal",
        title: venue.name,
        summary: venue.address,
        venue_name: venue.name,
        distance_km: venue.distance_km,
        latitude: venue.latitude,
        longitude: venue.longitude,
        provider: venue.provider,
        external_id: venue.external_id,
        url: venue.url,
        image_url: nil,
        rating: venue.rating,
        rating_count: venue.rating_count,
        metadata: {
          price_level: venue.price_level,
          types: venue.types,
          verified_rating: true
        }
      }
    end

    def activity_attributes(item, trip, language)
      used_ids = trip_items(trip).where.not(recommendation_id: nil).pluck(:recommendation_id).to_set
      used_sources = trip_items(trip).where.not(external_id: nil).pluck(:provider, :external_id).to_set
      suggestion = @recommender.call(
        forecast: item.trip_day.daily_forecast,
        activity_kinds: trip.preferences.fetch("interests", []),
        max_distance_km: trip.max_distance_km.to_f,
        time_of_day: item.slot,
        language:,
        limit: 20
      ).find do |candidate|
        recommendation = candidate.recommendation
        used_ids.exclude?(recommendation.id) &&
          used_sources.exclude?([ recommendation.provider, recommendation.external_id ])
      end
      raise NoAlternativeError, "No different weather-safe stop is available for this period" unless suggestion

      recommendation = suggestion.recommendation
      {
        recommendation:,
        kind: recommendation.recommendation_type.in?(%w[event movie]) ?
          recommendation.recommendation_type : "activity",
        title: recommendation.title,
        summary: suggestion.reason,
        venue_name: recommendation.venue_name,
        distance_km: suggestion.distance_km,
        latitude: recommendation.metadata["latitude"],
        longitude: recommendation.metadata["longitude"],
        provider: recommendation.provider,
        external_id: recommendation.external_id,
        url: recommendation.url,
        image_url: recommendation.metadata["poster_url"] || recommendation.metadata["image_url"],
        rating: nil,
        rating_count: nil,
        metadata: {
          indoor: recommendation.indoor,
          planning_notes: suggestion.planning_notes,
          availability: suggestion.availability,
          recommended_periods: suggestion.recommended_periods
        }
      }
    end

    def trip_items(trip)
      ItineraryItem.joins(:trip_day).where(trip_days: { trip_id: trip.id })
    end
  end
end
