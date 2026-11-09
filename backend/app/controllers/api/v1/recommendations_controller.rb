module Api
  module V1
    class RecommendationsController < BaseController
      def index
        forecast = DailyForecast.includes(:location).find(params[:forecast_id])
        suggestions = Recommendations::Rank.new.call(
          forecast:,
          type: recommendation_type,
          genre: params[:genre],
          setting: recommendation_setting,
          activity_kind: activity_kind,
          max_distance_km: max_distance_km,
          time_of_day: time_of_day,
          language: requested_language,
          excluded_movie_ids: excluded_movie_ids,
          limit: params.fetch(:limit, Recommendations::Rank::DEFAULT_LIMIT)
        )

        render json: {
          data: {
            forecast: forecast_json(forecast),
            recommendations: suggestions.map { |suggestion| recommendation_json(suggestion) }
          },
          meta: {
            count: suggestions.size,
            filters: {
              type: recommendation_type,
              genre: params[:genre].presence,
              setting: recommendation_setting,
              activity_kind: activity_kind,
              max_distance_km: max_distance_km,
              time_of_day: time_of_day,
              language: requested_language
            },
            movie_personality: Recommendations::MovieCurator.new.persona_key(forecast.location)
          }
        }
      end

      private

      def recommendation_type
        value = params[:type].presence
        return value if value.nil? || Recommendation::TYPES.include?(value)

        raise ActionController::BadRequest, "type must be activity, event, or movie"
      end

      def recommendation_setting
        value = params[:setting].presence
        return value if value.nil? || value.in?(%w[indoor outdoor])

        raise ActionController::BadRequest, "setting must be indoor or outdoor"
      end

      def activity_kind
        value = params[:activity_kind].presence
        return value if value.nil? || Recommendations::Rank::ACTIVITY_STYLES.key?(value)

        raise ActionController::BadRequest, "activity_kind must be culture, nature, or entertainment"
      end

      def max_distance_km
        return unless params[:max_distance_km].present?

        value = Float(params[:max_distance_km], exception: false)
        return value if value&.between?(0.5, 50.0)

        raise ActionController::BadRequest, "max_distance_km must be between 0.5 and 50"
      end

      def time_of_day
        value = params[:time_of_day].presence
        return value if value.nil? || Recommendations::Timing::PERIODS.include?(value)

        raise ActionController::BadRequest, "time_of_day must be morning, afternoon, or evening"
      end

      def excluded_movie_ids
        values = params[:exclude_movie_ids].to_s.split(",").filter_map do |value|
          Integer(value, exception: false)
        end.uniq
        raise ActionController::BadRequest, "exclude_movie_ids accepts at most 100 ids" if values.size > 100

        values
      end

      def recommendation_json(suggestion)
        item = suggestion.recommendation
        {
          id: item.id,
          type: item.recommendation_type,
          title: localized_attribute(item, "title"),
          summary: localized_attribute(item, "summary"),
          venue_name: item.venue_name,
          indoor: item.indoor,
          genres: item.genres,
          tags: item.tags,
          url: item.url,
          provider: item.provider,
          distance_km: suggestion.distance_km,
          coordinates: coordinates_for(item),
          image_url: item.metadata["poster_url"] || item.metadata["image_url"],
          image_attribution: image_attribution_for(item),
          opening_hours: item.metadata["opening_hours"],
          activity_kind: item.metadata["activity_kind"],
          weather_sensitive: item.metadata["weather_sensitivity"].present?,
          elevation_m: item.metadata["elevation_m"],
          route_distance_km: item.metadata["route_distance_km"],
          route_start: item.metadata["route_start"],
          route_end: item.metadata["route_end"],
          duration_minutes: item.metadata["duration_minutes"],
          ascent_m: item.metadata["ascent_m"],
          descent_m: item.metadata["descent_m"],
          roundtrip: item.metadata["roundtrip"],
          difficulty: item.metadata["difficulty"],
          trail_visibility: item.metadata["trail_visibility"],
          surface: item.metadata["surface"],
          route_network: item.metadata["network"],
          route_ref: item.metadata["route_ref"],
          trail_marker: item.metadata["trail_marker"],
          route_operator: item.metadata["route_operator"],
          official_url: item.metadata["official_url"],
          event_date: item.metadata["event_date"],
          event_time: item.metadata["event_time"],
          event_timezone: item.metadata["event_timezone"],
          event_status: item.metadata["event_status"],
          price_label: item.metadata["price_label"],
          recommended_periods: suggestion.recommended_periods,
          availability: suggestion.availability,
          rating: item.metadata["rating"],
          release_date: item.metadata["release_date"],
          attribution: attribution_for(item.provider),
          score: suggestion.score,
          reason: suggestion.reason,
          planning_notes: suggestion.planning_notes
        }
      end

      def localized_attribute(item, attribute)
        translations = item.metadata["translations"] || {}
        translations.dig(requested_language, attribute).presence || item.public_send(attribute)
      end

      def coordinates_for(item)
        latitude = item.metadata["latitude"]
        longitude = item.metadata["longitude"]
        return unless latitude && longitude

        { latitude:, longitude: }
      end

      def attribution_for(provider)
        case provider
        when "openstreetmap"
          {
            label: "© OpenStreetMap contributors",
            url: "https://www.openstreetmap.org/copyright"
          }
        when "tmdb"
          {
            label: "TMDB",
            url: "https://www.themoviedb.org",
            notice: "This product uses the TMDB API but is not endorsed or certified by TMDB."
          }
        when "ticketmaster"
          {
            label: "Ticketmaster",
            url: "https://www.ticketmaster.com"
          }
        when "predicthq"
          {
            label: "Event data by PredictHQ",
            url: "https://www.predicthq.com"
          }
        when "wikipedia"
          {
            label: "Place information from Wikipedia",
            url: "https://www.wikipedia.org"
          }
        end
      end

      def image_attribution_for(item)
        return unless item.metadata["image_attribution"].present?

        {
          label: item.metadata["image_attribution"],
          url: item.metadata["image_source_url"]
        }
      end
    end
  end
end
