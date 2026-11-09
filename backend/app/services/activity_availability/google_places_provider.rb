module ActivityAvailability
  class GooglePlacesProvider < Provider
    ENDPOINT = "https://places.googleapis.com/v1/places:searchText"
    PERIOD_MINUTES = Recommendations::Timing::PERIOD_MINUTES
    MAX_MATCH_DISTANCE_KM = 1.0

    def initialize(
      client: ExternalApi::HttpClient.new,
      api_key: ENV["GOOGLE_PLACES_API_KEY"],
      endpoint: ENV.fetch("GOOGLE_PLACES_API_URL", ENDPOINT),
      clock: Time
    )
      @client = client
      @api_key = api_key
      @endpoint = endpoint
      @clock = clock
    end

    def name = "google_places"

    def check(recommendation:, forecast:, period:)
      raise ArgumentError, "GOOGLE_PLACES_API_KEY is required" if @api_key.blank?

      place = matched_place(recommendation, forecast)
      return unmatched_result(recommendation, period) unless place

      checked_at = @clock.current
      status = place["businessStatus"]
      return closure_result(place, period, checked_at, status) if status.in?(%w[CLOSED_TEMPORARILY CLOSED_PERMANENTLY])

      hours = place["currentOpeningHours"]
      return hours_unavailable_result(place, period, checked_at) unless hours

      target_date = forecast.forecast_date
      local_today = checked_at.in_time_zone(forecast.location.timezone).to_date
      return outside_window_result(place, period, checked_at) unless target_date.between?(local_today, local_today + 6.days)

      open = open_during?(hours.fetch("periods", []), target_date, PERIOD_MINUTES.fetch(period))
      Result.new(
        status: open ? "verified_open" : "verified_closed",
        label: open ? "Provider lists this place open in the #{period}" : "Provider lists this place closed in the #{period}",
        detail: "Checked against current provider hours. Schedules can still change; confirm before leaving.",
        period:,
        provider: name,
        checked_at: checked_at.iso8601,
        place_name: place.dig("displayName", "text"),
        place_url: place["googleMapsUri"]
      )
    end

    private

    def matched_place(recommendation, forecast)
      payload = @client.post_json(
        URI(@endpoint),
        body: request_body(recommendation, forecast),
        headers: {
          "Content-Type" => "application/json",
          "X-Goog-Api-Key" => @api_key,
          "X-Goog-FieldMask" => "places.id,places.displayName,places.location,places.businessStatus,places.currentOpeningHours,places.googleMapsUri"
        }
      )
      Array(payload["places"])
        .select { |place| plausible_name?(recommendation, place) }
        .select { |place| nearby?(recommendation, place) }
        .min_by { |place| distance_km(recommendation, place) }
    end

    def request_body(recommendation, forecast)
      latitude = recommendation.metadata["latitude"] || forecast.location.latitude
      longitude = recommendation.metadata["longitude"] || forecast.location.longitude
      {
        textQuery: "#{recommendation.venue_name.presence || recommendation.title}, #{forecast.location.display_name}",
        pageSize: 3,
        languageCode: ENV.fetch("GOOGLE_PLACES_LANGUAGE", "en"),
        locationBias: {
          circle: {
            center: { latitude: latitude.to_f, longitude: longitude.to_f },
            radius: 1_000.0
          }
        }
      }
    end

    def plausible_name?(recommendation, place)
      expected = normalized_tokens(recommendation.venue_name.presence || recommendation.title)
      actual = normalized_tokens(place.dig("displayName", "text"))
      return false if expected.empty? || actual.empty?
      return expected == actual if expected.one? || actual.one?

      overlap = (expected & actual).size.to_f
      overlap / expected.size >= 0.6 && overlap / (expected | actual).size >= 0.5
    end

    def normalized_tokens(value)
      value.to_s.unicode_normalize(:nfkd).encode("ASCII", invalid: :replace, undef: :replace, replace: "")
        .downcase.scan(/[a-z0-9]+/).reject { |token| token.length < 2 || token.in?(%w[the of de la]) }.uniq
    end

    def nearby?(recommendation, place)
      return false unless recommendation.metadata["latitude"] && recommendation.metadata["longitude"]
      return false unless place.dig("location", "latitude") && place.dig("location", "longitude")

      distance_km(recommendation, place) <= MAX_MATCH_DISTANCE_KM
    end

    def distance_km(recommendation, place)
      latitude = recommendation.metadata["latitude"]
      longitude = recommendation.metadata["longitude"]
      place_latitude = place.dig("location", "latitude")
      place_longitude = place.dig("location", "longitude")
      return Float::INFINITY unless latitude && longitude && place_latitude && place_longitude

      haversine(latitude.to_f, longitude.to_f, place_latitude.to_f, place_longitude.to_f)
    end

    def haversine(latitude_a, longitude_a, latitude_b, longitude_b)
      radius = 6_371.0
      latitude_delta = radians(latitude_b - latitude_a)
      longitude_delta = radians(longitude_b - longitude_a)
      a = Math.sin(latitude_delta / 2)**2 +
        Math.cos(radians(latitude_a)) * Math.cos(radians(latitude_b)) * Math.sin(longitude_delta / 2)**2
      radius * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
    end

    def radians(value) = value * Math::PI / 180

    def open_during?(periods, date, target_minute)
      target = Time.utc(date.year, date.month, date.day, target_minute / 60, target_minute % 60)
      periods.any? do |period|
        opens_at = point_time(period["open"])
        closes_at = point_time(period["close"])
        opens_at && opens_at <= target && (closes_at.nil? || target < closes_at)
      end
    end

    def point_time(point)
      return unless point

      date = point["date"]
      return unless date

      Time.utc(date.fetch("year"), date.fetch("month"), date.fetch("day"), point.fetch("hour", 0), point.fetch("minute", 0))
    end

    def closure_result(place, period, checked_at, status)
      permanent = status == "CLOSED_PERMANENTLY"
      Result.new(
        status: permanent ? "permanently_closed" : "temporarily_closed",
        label: permanent ? "Provider marks this place permanently closed" : "Provider marks this place temporarily closed",
        detail: "This status was checked live. Choose another activity or confirm directly with the venue.",
        period:,
        provider: name,
        checked_at: checked_at.iso8601,
        place_name: place.dig("displayName", "text"),
        place_url: place["googleMapsUri"]
      )
    end

    def unmatched_result(recommendation, period)
      Result.new(
        status: "match_uncertain",
        label: "A reliable live match was not found",
        detail: "Use the listed hours and confirm with the venue before visiting.",
        period:,
        provider: name,
        checked_at: @clock.current.iso8601,
        place_name: recommendation.venue_name.presence || recommendation.title,
        place_url: recommendation.url
      )
    end

    def hours_unavailable_result(place, period, checked_at)
      Result.new(
        status: "hours_unavailable",
        label: "Current hours are not supplied for this place",
        detail: "Confirm directly with the venue before visiting.",
        period:,
        provider: name,
        checked_at: checked_at.iso8601,
        place_name: place.dig("displayName", "text"),
        place_url: place["googleMapsUri"]
      )
    end

    def outside_window_result(place, period, checked_at)
      Result.new(
        status: "outside_window",
        label: "Live hours are not available this far ahead",
        detail: "Try again within seven days of the visit, then confirm before leaving.",
        period:,
        provider: name,
        checked_at: checked_at.iso8601,
        place_name: place.dig("displayName", "text"),
        place_url: place["googleMapsUri"]
      )
    end
  end
end
