module Recommendations
  RankedSuggestion = Data.define(
    :recommendation,
    :score,
    :reason,
    :planning_notes,
    :distance_km,
    :recommended_periods,
    :availability
  )

  class Rank
    DEFAULT_LIMIT = 6
    ACTIVITY_STYLES = {
      "culture" => %w[culture museum history art gallery],
      "nature" => %w[nature park garden walk hiking photography],
      "entertainment" => %w[entertainment cinema bowling escape_room theatre]
    }.freeze

    def initialize(provider: CacheFirstProvider.new, timing: Timing.new, movie_curator: MovieCurator.new, event_deduplicator: EventDeduplicator.new)
      @provider = provider
      @timing = timing
      @movie_curator = movie_curator
      @event_deduplicator = event_deduplicator
    end

    def call(forecast:, type: nil, genre: nil, setting: nil, activity_kind: nil, activity_kinds: [], max_distance_km: nil, time_of_day: nil, language: "en", excluded_movie_ids: [], limit: DEFAULT_LIMIT)
      preferences = {
        type: type.presence,
        genre: normalize_genre(genre),
        setting: setting.presence,
        activity_kind: activity_kind.presence,
        activity_kinds: Array(activity_kinds).map(&:to_s).select { |value| ACTIVITY_STYLES.key?(value) }.uniq,
        max_distance_km:,
        time_of_day:,
        excluded_movie_ids: Array(excluded_movie_ids).map(&:to_i).to_set,
        language: normalize_language(language)
      }
      request = Request.new(location: forecast.location, forecast:, preferences:)
      candidates = @provider.suggestions(request:)
      candidates = @event_deduplicator.call(candidates)
      candidates.reject! do |item|
        item.recommendation_type == "event" && item.metadata["event_date"] != forecast.forecast_date.iso8601
      end
      candidates.select! { |item| forecast_eligible?(item, forecast) }
      candidates.select! { |item| item.recommendation_type == preferences[:type] } if preferences[:type]
      candidates.reject! do |item|
        item.recommendation_type == "movie" && preferences[:excluded_movie_ids].include?(item.id)
      end
      if preferences[:genre]
        candidates.select! do |item|
          item.recommendation_type != "movie" || matches_genre?(item, preferences[:genre])
        end
      end
      candidates.select! { |item| matches_setting?(item, preferences[:setting]) } if preferences[:setting]
      candidates.select! { |item| matches_activity_style?(item, preferences[:activity_kind]) } if preferences[:activity_kind]
      if preferences[:activity_kinds].any?
        candidates.select! do |item|
          item.recommendation_type != "activity" || preferences[:activity_kinds].any? do |kind|
            matches_activity_style?(item, kind)
          end
        end
      end
      candidates.select! { |item| within_distance?(item, forecast.location, preferences[:max_distance_km]) } if preferences[:max_distance_km]
      if preferences[:time_of_day]
        candidates.select! { |item| @timing.periods(item).include?(preferences[:time_of_day]) }
        candidates.reject! do |item|
          @timing.availability(item:, date: forecast.forecast_date, period: preferences[:time_of_day])&.dig(:status) == "listed_closed"
        end
      end

      ranked = candidates.map { |item| rank(item, forecast, preferences) }
        .sort_by { |result| [ -result.score, result.recommendation.title ] }
      diversify(ranked, limit.to_i.clamp(1, 20), preferences[:type])
    end

    private

    def diversify(results, limit, requested_type)
      return results.first(limit) if requested_type.in?(%w[movie event])

      groups = results.group_by { |result| diversity_key(result.recommendation) }
      ordered_keys = groups.keys.sort_by do |key|
        best = groups.fetch(key).first
        [ -best.score, key ]
      end
      selected = []
      loop do
        added = false
        ordered_keys.each do |key|
          candidate = groups.fetch(key).shift
          next unless candidate

          selected << candidate
          added = true
          return selected if selected.size == limit
        end
        break unless added
      end
      selected
    end

    def diversity_key(item)
      return item.recommendation_type unless item.recommendation_type == "activity"

      category = item.metadata["activity_category"].presence || activity_category_from_tags(item.tags)
      "activity:#{category}"
    end

    def activity_category_from_tags(tags)
      normalized = tags.map(&:downcase)
      return "trail" if normalized.intersect?(%w[route trail])
      return "peak" if normalized.intersect?(%w[peak summit])
      return "mountain_shelter" if normalized.intersect?(%w[shelter alpine_hut wilderness_hut])
      return "viewpoint" if normalized.include?("viewpoint")
      return "park" if normalized.intersect?(%w[park garden nature_reserve])
      return "museum" if normalized.intersect?(%w[museum gallery])
      return "heritage" if normalized.intersect?(%w[heritage history monument])
      return "entertainment" if normalized.include?("entertainment")

      "other"
    end

    def normalize_language(language)
      value = language.to_s.downcase.split("-").first
      %w[en ro].include?(value) ? value : "en"
    end

    def rank(item, forecast, preferences)
      distance = distance_for(item, forecast.location)
      score = context_score(item, forecast.activity_context)
      score += 20 if item.weather_classes.include?(forecast.weather_class)
      score += 10 if item.location_id == forecast.location_id
      score += 5 if item.recommendation_type == "activity"
      score += proximity_score(distance)
      score += 8 if preferences[:genre] && item.recommendation_type == "movie" && matches_genre?(item, preferences[:genre])
      score += 8 if preferences[:activity_kind] && item.recommendation_type == "activity" && matches_activity_style?(item, preferences[:activity_kind])
      if item.recommendation_type == "activity" && preferences[:activity_kinds].any? do |kind|
        matches_activity_style?(item, kind)
      end
        score += 8
      end
      score += 6 if preferences[:setting] && matches_setting?(item, preferences[:setting])
      score += 12 if preferences[:time_of_day] && @timing.periods(item).include?(preferences[:time_of_day])
      score += @movie_curator.adjustment(item:, forecast:)
      score += activity_feature_score(item)
      score -= uv_exposure_penalty(item, forecast)

      availability = @timing.availability(
        item:,
        date: forecast.forecast_date,
        period: preferences[:time_of_day]
      )

      RankedSuggestion.new(
        recommendation: item,
        score:,
        reason: reason(item, forecast, preferences, distance, preferences[:language]),
        planning_notes: planning_notes(item, forecast, preferences[:language]),
        distance_km: distance,
        recommended_periods: @timing.periods(item),
        availability:
      )
    end

    def proximity_score(distance)
      return 0 unless distance

      (10 - distance.to_f).ceil.clamp(0, 10)
    end

    def activity_feature_score(item)
      return 0 unless item.recommendation_type == "activity"

      score = 0
      score += (item.metadata["elevation_m"].to_i / 200).clamp(0, 10)
      score += (item.metadata["prominence_m"].to_i / 100).clamp(0, 5)
      score += 6 if item.tags.include?("route")
      score += route_completeness_score(item)
      score += 5 if item.metadata["image_url"].present?
      score
    end

    def route_completeness_score(item)
      return 0 unless item.tags.include?("route")

      %w[
        route_distance_km route_start route_end duration_minutes ascent_m
        difficulty trail_marker
      ].count { |key| item.metadata[key].present? }.clamp(0, 7)
    end

    def uv_exposure_penalty(item, forecast)
      return 0 unless exposed_outdoor?(item)

      ((forecast.uv_index_max.to_f - 7) * 4).round.clamp(0, 20)
    end

    def planning_notes(item, forecast, language)
      notes = []
      if weather_sensitive?(item)
        notes << {
          code: "verify_trail_conditions",
          severity: "moderate",
          message: trail_message(forecast, language)
        }
      end
      if exposed_outdoor?(item) && forecast.uv_index_max.to_f >= 8
        extreme = forecast.uv_index_max.to_f >= 11
        uv_value = format("%.1f", forecast.uv_index_max)
        notes << {
          code: extreme ? "extreme_uv" : "very_high_uv",
          severity: extreme ? "high" : "moderate",
          message: uv_message(uv_value, language)
        }
      end
      notes
    end

    def trail_message(forecast, language)
      daylight_hours = forecast.daylight_duration_seconds.to_i / 3600.0
      if language == "ro"
        return "Prognoza locală pentru #{forecast.location.name} trece filtrul de bază și oferă aproximativ #{format('%.1f', daylight_hours)} ore de lumină. Nu verifică vremea pe traseu sau la altitudine; confirmă prognoza montană, marcajele și avertizările Salvamont înainte de plecare."
      end

      "The local forecast for #{forecast.location.name} passes the baseline filter and offers about #{format('%.1f', daylight_hours)} daylight hours. It does not verify weather along the route or at elevation; check the mountain forecast, trail status, and rescue advisories before leaving."
    end

    def uv_message(uv_value, language)
      return "Indicele UV ajunge la #{uv_value}; caută umbra în jurul prânzului și folosește protecție solară." if language == "ro"

      "UV peaks at #{uv_value}; favor shade around midday and use sun protection."
    end

    def exposed_outdoor?(item)
      !item.indoor? && item.metadata["setting"] != "unknown"
    end

    def weather_sensitive?(item)
      item.recommendation_type == "activity" && item.metadata["weather_sensitivity"].present?
    end

    def forecast_eligible?(item, forecast)
      return true unless weather_sensitive?(item)

      case item.metadata["weather_sensitivity"]
      when "dry_daylight"
        dry_outdoor_forecast?(forecast) && sufficient_daylight?(forecast, 8)
      when "outdoor_daylight"
        comfortable_outdoor_forecast?(forecast) && sufficient_daylight?(forecast, 6)
      else
        true
      end
    end

    def dry_outdoor_forecast?(forecast)
      forecast.weather_class.in?(%w[clear cloudy]) &&
        forecast.activity_context.in?(%w[outdoor flexible]) &&
        forecast.precipitation_probability.to_i <= 25 &&
        forecast.precipitation_mm.to_f <= 1.0 &&
        forecast.wind_speed_kph.to_f <= 35
    end

    def comfortable_outdoor_forecast?(forecast)
      forecast.weather_class.in?(%w[clear cloudy]) &&
        forecast.activity_context.in?(%w[outdoor flexible]) &&
        forecast.precipitation_probability.to_i <= 40 &&
        forecast.wind_speed_kph.to_f <= 45
    end

    def sufficient_daylight?(forecast, minimum_hours)
      forecast.sunrise_local.present? && forecast.sunset_local.present? &&
        forecast.daylight_duration_seconds.to_i >= minimum_hours.hours.to_i
    end

    def matches_setting?(item, setting)
      return false if item.metadata["setting"] == "unknown"

      setting == "indoor" ? item.indoor? : !item.indoor?
    end

    def matches_genre?(item, genre)
      item.genres.any? { |value| normalize_genre(value) == genre }
    end

    def normalize_genre(value)
      value.presence&.downcase&.gsub(/[^a-z0-9]+/, "-")&.delete_suffix("-")&.delete_prefix("-")
    end

    def matches_activity_style?(item, activity_kind)
      return true unless item.recommendation_type == "activity"

      item.metadata["activity_kind"] == activity_kind ||
        (item.tags.map(&:downcase) & ACTIVITY_STYLES.fetch(activity_kind)).any?
    end

    def within_distance?(item, location, max_distance_km)
      return true unless item.recommendation_type == "activity"

      distance = distance_for(item, location)
      distance && distance <= max_distance_km
    end

    def distance_for(item, location)
      supplied_distance = item.metadata["distance_km"]
      return supplied_distance.to_f.round(1) if supplied_distance

      latitude = item.metadata["latitude"]
      longitude = item.metadata["longitude"]
      return unless latitude && longitude

      haversine_distance(
        location.latitude.to_f,
        location.longitude.to_f,
        latitude.to_f,
        longitude.to_f
      ).round(1)
    end

    def haversine_distance(latitude_a, longitude_a, latitude_b, longitude_b)
      earth_radius_km = 6371.0
      latitude_delta = degrees_to_radians(latitude_b - latitude_a)
      longitude_delta = degrees_to_radians(longitude_b - longitude_a)
      a = Math.sin(latitude_delta / 2)**2 +
        Math.cos(degrees_to_radians(latitude_a)) * Math.cos(degrees_to_radians(latitude_b)) *
        Math.sin(longitude_delta / 2)**2

      earth_radius_km * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
    end

    def degrees_to_radians(value)
      value * Math::PI / 180
    end

    def context_score(item, context)
      return 25 if item.metadata["setting"] == "unknown"

      case context
      when "indoor" then item.indoor? ? 50 : 0
      when "outdoor" then item.indoor? ? 5 : 50
      when "caution" then item.indoor? ? 40 : 0
      else 25
      end
    end

    def reason(item, forecast, preferences, distance, language)
      return romanian_reason(item, forecast, preferences, distance) if language == "ro"
      if item.metadata["weather_sensitivity"] == "dry_daylight"
        return "The local forecast for #{forecast.location.name} passes the baseline hiking filter; mountain conditions remain unverified"
      end

      if preferences[:time_of_day]
        return "Fits your #{preferences[:time_of_day]} plan and this forecast"
      end
      if preferences[:genre] && item.recommendation_type == "movie"
        return "Matches your #{preferences[:genre].titleize} movie mood"
      end
      if preferences[:activity_kind] && item.recommendation_type == "activity"
        return "A #{preferences[:activity_kind]} pick suited to this forecast"
      end
      if preferences[:setting]
        return "Matches your #{preferences[:setting]} preference for this day"
      end
      if item.recommendation_type == "movie"
        return @movie_curator.reason(forecast:, language:)
      end
      if preferences[:max_distance_km] && distance && item.recommendation_type == "activity"
        return "A weather-friendly option #{format('%.1f', distance)} km away"
      end
      if item.recommendation_type == "event"
        return "Scheduled locally for this forecast day; venue setting is unverified"
      end
      return "A sheltered choice for #{forecast.condition_label.downcase} conditions" if item.indoor? && forecast.activity_context.in?(%w[indoor caution])
      return "Makes the most of the clear outdoor window" if !item.indoor? && forecast.activity_context == "outdoor"
      return "Especially suited to #{forecast.condition_label.downcase} weather" if item.weather_classes.include?(forecast.weather_class)

      "A flexible match for this forecast"
    end

    def romanian_reason(item, forecast, preferences, distance)
      if item.metadata["weather_sensitivity"] == "dry_daylight"
        return "Prognoza locală pentru #{forecast.location.name} trece filtrul de bază; condițiile montane rămân neverificate"
      end

      if preferences[:time_of_day]
        period = { "morning" => "dimineață", "afternoon" => "după-amiază", "evening" => "seară" }
          .fetch(preferences[:time_of_day], preferences[:time_of_day])
        return "Se potrivește planului tău pentru #{period} și acestei prognoze"
      end
      if preferences[:genre] && item.recommendation_type == "movie"
        return "Se potrivește preferinței tale pentru filme #{preferences[:genre].titleize.downcase}"
      end
      if preferences[:activity_kind] && item.recommendation_type == "activity"
        kind = { "culture" => "cultură", "nature" => "natură", "entertainment" => "divertisment" }
          .fetch(preferences[:activity_kind], preferences[:activity_kind])
        return "O alegere de #{kind} potrivită acestei prognoze"
      end
      if preferences[:setting]
        setting = preferences[:setting] == "indoor" ? "în interior" : "în aer liber"
        return "Respectă preferința ta pentru activități #{setting} în această zi"
      end
      if item.recommendation_type == "movie"
        return @movie_curator.reason(forecast:, language: "ro")
      end
      if preferences[:max_distance_km] && distance && item.recommendation_type == "activity"
        return "O opțiune potrivită vremii, la #{format('%.1f', distance)} km"
      end
      if item.recommendation_type == "event"
        return "Programat local pentru această zi; spațiul evenimentului nu este verificat"
      end
      return "O alegere la adăpost, potrivită condițiilor de azi" if item.indoor? && forecast.activity_context.in?(%w[indoor caution])
      return "Profită de intervalul senin pentru activități în aer liber" if !item.indoor? && forecast.activity_context == "outdoor"
      return "Potrivită în special vremii prognozate" if item.weather_classes.include?(forecast.weather_class)

      "O opțiune flexibilă pentru această prognoză"
    end
  end
end
