module Trips
  class Planner
    HourlyWeatherTimeout = Class.new(StandardError)

    def initialize(
      recommender: Recommendations::Rank.new(provider: Recommendations::CacheFirstProvider.new),
      dining_provider: Dining::ProviderFactory.build,
      forecast_fetcher: Forecasts::Fetch.new,
      hourly_fetcher: HourlyForecasts::Fetch.new,
      route_annotator: RouteAnnotator.new
    )
      @recommender = recommender
      @dining_provider = dining_provider
      @forecast_fetcher = forecast_fetcher
      @hourly_fetcher = hourly_fetcher
      @route_annotator = route_annotator
    end

    def call(trip:, language: "en", refresh_weather: false)
      forecasts = forecasts_for(trip, refresh: refresh_weather)
      hourly_forecasts = hourly_forecasts_for(forecasts.values, refresh: refresh_weather)
      used_recommendations = Set.new
      used_venues = Set.new

      Trip.transaction do
        trip.trip_days.destroy_all
        @route_annotator.reset!
        dining = dining_suggestions(trip, language)
        (trip.starts_on..trip.ends_on).each do |date|
          forecast = forecasts.fetch(date)
          trip_day = trip.trip_days.create!(day_attributes(forecast, language))
          activities = activity_suggestions(trip, forecast, language, used_recommendations)
          periods = DailyRhythm.periods_for(trip, date)
          previous_point = point_for(trip.location)
          periods.each_with_index do |period, position|
            period_weather = PeriodWeather.new(
              hours: hourly_forecasts.fetch(date, []), period:, forecast:
            )
            attributes = if period.fetch(:kind) == "meal"
              meal_attributes(period.fetch(:slot), dining, used_venues, language, previous_point)
            elsif period.fetch(:kind) == "rest"
              rest_attributes(language, trip.pace)
            else
              activity_attributes(
                period, activities, used_recommendations, forecast, language, trip, period_weather,
                previous_point
              )
            end
            attributes[:metadata] = attributes.fetch(:metadata, {}).merge(
              period_weather: period_weather.payload
            )
            persisted_period = period.merge(kind: period.fetch(:kind) == "rest" ? "free_time" : period.fetch(:kind))
            item = trip_day.itinerary_items.create!(persisted_period.merge(attributes).merge(position:))
            previous_point = point_for(item) if item.latitude.present? && item.longitude.present?
          end
          @route_annotator.call(trip_day:, trip:, language:)
          trip_day.update!(summary: DayNarrative.new(trip_day:, forecast:, language:).call)
        end
        trip.update!(status: "planned")
      end
      trip.reload
    end

    private

    def hourly_forecasts_for(forecasts, refresh:)
      timeout_seconds = ENV.fetch("TRIP_HOURLY_TIMEOUT_SECONDS", 8).to_f.clamp(1, 30)
      Timeout.timeout(timeout_seconds, HourlyWeatherTimeout) do
        @hourly_fetcher.call_range(daily_forecasts: forecasts, refresh:)
      end
    rescue ExternalApi::Error, HourlyWeatherTimeout => error
      Rails.logger.warn("Hourly weather unavailable for trip planning: #{error.message}")
      {}
    end

    def forecasts_for(trip, refresh:)
      if refresh
        @forecast_fetcher.call(
          location: trip.location,
          days: forecast_days_for(trip),
          refresh: true
        )
      end

      existing = stored_forecasts(trip)
      missing = (trip.starts_on..trip.ends_on).reject { |date| existing.key?(date) }
      if missing.any?
        @forecast_fetcher.call(location: trip.location, days: forecast_days_for(trip))
        existing = stored_forecasts(trip)
      end
      absent = (trip.starts_on..trip.ends_on).reject { |date| existing.key?(date) }
      raise ActionController::BadRequest, "weather is unavailable for #{absent.first}" if absent.any?

      existing
    end

    def stored_forecasts(trip)
      trip.location.daily_forecasts
        .where(forecast_date: trip.starts_on..trip.ends_on)
        .order(:fetched_at)
        .index_by(&:forecast_date)
    end

    def forecast_days_for(trip)
      ((trip.ends_on - Date.current).to_i + 1).clamp(1, Trip::MAX_DAYS)
    end

    def day_attributes(forecast, language)
      {
        date: forecast.forecast_date,
        daily_forecast: forecast,
        weather_class: forecast.weather_class,
        activity_context: forecast.activity_context,
        summary: day_summary(forecast, language),
        weather_snapshot: {
          condition: forecast.condition_label,
          minimum_c: forecast.temperature_min_c.to_f,
          maximum_c: forecast.temperature_max_c.to_f,
          rain_probability: forecast.precipitation_probability,
          wind_kph: forecast.wind_speed_kph.to_f
        }
      }
    end

    def activity_suggestions(trip, forecast, language, used)
      @recommender.call(
        forecast:,
        activity_kinds: trip.preferences.fetch("interests", []),
        max_distance_km: trip.max_distance_km.to_f,
        language:,
        limit: 20
      ).reject { |suggestion| used.include?(suggestion.recommendation.id) }
    end

    def dining_suggestions(trip, language)
      %w[breakfast lunch dinner].to_h do |meal|
        venues = @dining_provider.search(
          location: trip.location,
          meal:,
          radius_km: trip.max_distance_km.to_f,
          language:,
          preferences: trip.preferences
        )
        [ meal, venues ]
      rescue ExternalApi::Error => error
        Rails.logger.warn("Dining discovery unavailable: #{error.message}")
        [ meal, [] ]
      end
    end

    def meal_attributes(slot, dining, used, language, origin)
      venue = dining.fetch(slot)
        .reject { |candidate| used.include?(candidate.external_id) }
        .min_by { |candidate| venue_sequence_key(candidate, origin) }
      return missing_meal(slot, language) unless venue

      used.add(venue.external_id)
      sequence_distance = GeoDistance.km(origin, point_for(venue))

      {
        title: venue.name,
        summary: venue.address,
        venue_name: venue.name,
        distance_km: venue.distance_km,
        latitude: venue.latitude,
        longitude: venue.longitude,
        provider: venue.provider,
        external_id: venue.external_id,
        url: venue.url,
        rating: venue.rating,
        rating_count: venue.rating_count,
        metadata: {
          price_level: venue.price_level,
          types: venue.types,
          verified_rating: true,
          selection_distance_from_previous_km: sequence_distance
        }.compact
      }
    end

    def missing_meal(slot, language)
      romanian = language.to_s.start_with?("ro")
      labels = romanian ? { "breakfast" => "Mic dejun", "lunch" => "Prânz", "dinner" => "Cină" } :
        { "breakfast" => "Breakfast", "lunch" => "Lunch", "dinner" => "Dinner" }
      {
        title: labels.fetch(slot),
        summary: romanian ?
          "Conectează Google Places pentru localuri reale cu rating de cel puțin 4,0." :
          "Connect Google Places for real venues rated at least 4.0.",
        status: "unavailable",
        metadata: { reason: "dining_provider_unavailable", minimum_rating: 4.0 }
      }
    end

    def activity_attributes(period, suggestions, used, forecast, language, trip, period_weather, origin)
      slot = period.fetch(:slot)
      suggestion = suggestions.select do |candidate|
        candidate.recommended_periods.include?(slot) &&
          fits_period?(candidate.recommendation, period) &&
          period_weather.safe_for?(candidate.recommendation) &&
          !used.include?(candidate.recommendation.id)
      end.min_by do |candidate|
        recommendation_sequence_key(candidate, period_weather, origin)
      end
      return free_time(slot, forecast, language) unless suggestion

      item = suggestion.recommendation
      used.add(item.id)
      starts_at, ends_at = scheduled_times(item, period)
      sequence_distance = GeoDistance.km(origin, point_for(item))
      {
        recommendation: item,
        kind: item.recommendation_type.in?(%w[event movie]) ? item.recommendation_type : "activity",
        title: item.title,
        summary: period_weather.reason_for(item, language:) || suggestion.reason,
        venue_name: item.venue_name,
        distance_km: suggestion.distance_km,
        latitude: item.metadata["latitude"],
        longitude: item.metadata["longitude"],
        provider: item.provider,
        external_id: item.external_id,
        url: item.url,
        image_url: item.metadata["poster_url"] || item.metadata["image_url"],
        starts_at:,
        ends_at:,
        metadata: {
          indoor: item.indoor,
          planning_notes: suggestion.planning_notes,
          availability: suggestion.availability,
          recommended_periods: suggestion.recommended_periods,
          duration_minutes: duration_minutes(item),
          travel_buffer_minutes: DailyRhythm.travel_buffer_minutes(trip.transport_mode),
          pace: trip.pace,
          ranking_reason: suggestion.reason,
          selection_distance_from_previous_km: sequence_distance
        }
      }
    end

    def recommendation_sequence_key(candidate, period_weather, origin)
      score = candidate.score.to_f
      distance = GeoDistance.km(origin, point_for(candidate.recommendation))
      [ period_weather.preference(candidate.recommendation), -(score / 10).floor, distance_band(distance), -score ]
    end

    def venue_sequence_key(venue, origin)
      distance = GeoDistance.km(origin, point_for(venue))
      [ distance_band(distance), -venue.rating.to_f, -venue.rating_count.to_i, venue.name ]
    end

    def distance_band(distance)
      return 0 unless distance

      (distance / 5.0).floor
    end

    def point_for(record)
      latitude = record.respond_to?(:latitude) ? record.latitude : record.metadata["latitude"]
      longitude = record.respond_to?(:longitude) ? record.longitude : record.metadata["longitude"]
      { latitude:, longitude: }
    end

    def fits_period?(item, period)
      duration = duration_minutes(item)
      event_time = item.recommendation_type == "event" ? item.metadata["event_time"].to_s.first(5) : nil
      starts_at = event_time.presence || period.fetch(:starts_at)
      start_minute = to_minutes(starts_at)
      period_start = to_minutes(period.fetch(:starts_at))
      period_end = to_minutes(period.fetch(:ends_at))
      return false unless start_minute.between?(period_start, period_end - 1)
      return true unless duration

      start_minute + duration <= period_end
    end

    def scheduled_times(item, period)
      event_time = item.recommendation_type == "event" ? item.metadata["event_time"].to_s.first(5) : nil
      starts_at = event_time.presence || period.fetch(:starts_at)
      duration = duration_minutes(item)
      ends_at = duration ? add_minutes(starts_at, duration) : period.fetch(:ends_at)
      [ starts_at, ends_at ]
    end

    def duration_minutes(item)
      value = item.metadata["duration_minutes"]
      value.to_i if value.to_i.positive?
    end

    def add_minutes(time, duration)
      total = to_minutes(time) + duration
      format("%02d:%02d", (total / 60) % 24, total % 60)
    end

    def to_minutes(time)
      hours, minutes = time.split(":").map(&:to_i)
      (hours * 60) + minutes
    end

    def rest_attributes(language, pace)
      romanian = language.to_s.start_with?("ro")
      {
        title: romanian ? "Seară fără program" : "Unscheduled evening",
        summary: romanian ?
          "Ritmul relaxat păstrează seara liberă pentru odihnă sau o plimbare spontană." :
          "The relaxed pace keeps this evening free for rest or a spontaneous walk.",
        metadata: { reason: "pace_rest", pace: }
      }
    end

    def free_time(slot, forecast, language)
      romanian = language.to_s.start_with?("ro")
      {
        kind: "free_time",
        title: romanian ? "Interval liber" : "Open time",
        summary: romanian ?
          "Nu am găsit încă o oprire sigură pentru vremea din acest interval." :
          "No weather-safe stop is available for this period yet.",
        status: "unavailable",
        metadata: { weather_class: forecast.weather_class, slot: }
      }
    end

    def day_summary(forecast, language)
      if language.to_s.start_with?("ro")
        "#{forecast.condition_label}, #{forecast.temperature_min_c.to_i}–#{forecast.temperature_max_c.to_i}°C, #{forecast.precipitation_probability}% ploaie"
      else
        "#{forecast.condition_label}, #{forecast.temperature_min_c.to_i}–#{forecast.temperature_max_c.to_i}°C, #{forecast.precipitation_probability}% rain"
      end
    end
  end
end
