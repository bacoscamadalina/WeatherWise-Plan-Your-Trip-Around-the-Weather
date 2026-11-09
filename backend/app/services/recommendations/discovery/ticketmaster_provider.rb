module Recommendations
  module Discovery
    class TicketmasterProvider < Provider
      ENDPOINT = "https://app.ticketmaster.com/discovery/v2/events.json"
      CANCELED_STATUSES = %w[canceled cancelled].freeze

      def initialize(
        client: ExternalApi::HttpClient.new,
        api_key: ENV["TICKETMASTER_API_KEY"],
        radius_km: ENV.fetch("EVENT_RADIUS_KM", 25).to_i
      )
        @client = client
        @api_key = api_key
        @radius_km = radius_km.clamp(1, 100)
      end

      def name = "ticketmaster"

      def cache_scope(request:)
        Recommendation.where(provider: name, location: request.location)
          .where("metadata ->> 'event_date' = ?", request.forecast.forecast_date.iso8601)
      end

      def discover(request:)
        raise ExternalApi::Error, "TICKETMASTER_API_KEY is not configured" if @api_key.blank?

        discover_range(
          location: request.location,
          forecasts: [ request.forecast ],
          language: request.preferences[:language]
        )
      end

      def discover_range(location:, forecasts:, language: "en")
        raise ExternalApi::Error, "TICKETMASTER_API_KEY is not configured" if @api_key.blank?
        return [] if forecasts.empty?

        forecasts_by_date = forecasts.index_by { |forecast| forecast.forecast_date.iso8601 }
        payload = @client.get_json(range_uri(location:, forecasts:, language:))
        Array(payload.dig("_embedded", "events")).filter_map do |event|
          forecast = forecasts_by_date[event.dig("dates", "start", "localDate")]
          next unless forecast

          request = Request.new(location:, forecast:, preferences: { language: })
          map(event, request)
        end
      end

      private

      def uri(request)
        range_uri(
          location: request.location,
          forecasts: [ request.forecast ],
          language: request.preferences[:language]
        )
      end

      def range_uri(location:, forecasts:, language: "en")
        dates = forecasts.map(&:forecast_date).minmax
        zone = ActiveSupport::TimeZone[location.timezone] || ActiveSupport::TimeZone["UTC"]
        start_time = zone.local(dates.first.year, dates.first.month, dates.first.day).utc.iso8601
        end_time = zone.local(dates.last.year, dates.last.month, dates.last.day).end_of_day.utc.iso8601
        language = language.presence || "en"

        URI(ENDPOINT).tap do |uri|
          uri.query = URI.encode_www_form(
            apikey: @api_key,
            geoPoint: Geohash.encode(location.latitude, location.longitude),
            radius: radius_for(location),
            unit: "km",
            countryCode: location.country_code,
            locale: "#{language}-#{location.country_code.to_s.downcase},#{language},*",
            startDateTime: start_time,
            endDateTime: end_time,
            includeTBA: "no",
            includeTBD: "no",
            includeTest: "no",
            sort: "distance,date,asc",
            size: forecasts.one? ? 50 : 200
          )
        end
      end

      def map(event, request)
        location = request.location
        title = event["name"].presence
        local_date = event.dig("dates", "start", "localDate").presence
        status = event.dig("dates", "status", "code").to_s.downcase
        return unless title && local_date == request.forecast.forecast_date.iso8601
        return if status.in?(CANCELED_STATUSES)

        venue = Array(event.dig("_embedded", "venues")).first || {}
        classification = Array(event["classifications"]).first || {}
        segment = classification.dig("segment", "name").presence
        genre = classification.dig("genre", "name").presence
        latitude = venue.dig("location", "latitude")
        longitude = venue.dig("location", "longitude")
        distance = distance_km(location, latitude, longitude)
        radius = radius_for(location)
        return if distance && distance > radius
        summary = event_summary(segment, genre, venue["name"], location.name)

        CatalogItem.new(
          location:,
          recommendation_type: "event",
          title:,
          summary:,
          venue_name: venue["name"].presence,
          indoor: true,
          provider: name,
          external_id: "#{location_cache_key(location)}:#{event.fetch('id')}",
          url: event["url"],
          genres: [ genre&.downcase ].compact,
          tags: [ "event", "live", "setting-unverified", segment&.downcase, genre&.downcase ].compact,
          weather_classes: %w[clear cloudy rain snow storm fog],
          metadata: {
            event_date: local_date,
            event_time: event.dig("dates", "start", "localTime"),
            event_timezone: event.dig("dates", "timezone"),
            event_status: status.presence,
            provider_event_id: event.fetch("id"),
            venue_city: venue.dig("city", "name"),
            venue_address: venue.dig("address", "line1"),
            latitude: latitude&.to_f,
            longitude: longitude&.to_f,
            distance_km: distance&.round(1),
            search_radius_km: radius,
            image_url: preferred_image(event["images"]),
            price_label: price_label(event["priceRanges"]),
            setting: "unknown",
            translations: {
              ro: {
                summary: romanian_event_summary(segment, genre, venue["name"], location.name)
              }
            }
          }.compact
        )
      end

      def radius_for(location)
        return @radius_km unless location.feature_code.to_s.start_with?("PPL")
        return @radius_km if location.population.to_i >= 20_000

        [ @radius_km * 2, 100 ].min
      end

      def location_cache_key(location)
        source = [ location.provider, location.external_id, location.country_code, location.latitude, location.longitude ].join(":")
        Digest::SHA256.hexdigest(source).first(12)
      end

      def distance_km(location, latitude, longitude)
        return unless latitude.present? && longitude.present?

        lat1 = location.latitude.to_f * Math::PI / 180
        lat2 = latitude.to_f * Math::PI / 180
        delta_lat = lat2 - lat1
        delta_lon = (longitude.to_f - location.longitude.to_f) * Math::PI / 180
        haversine = Math.sin(delta_lat / 2)**2 + Math.cos(lat1) * Math.cos(lat2) * Math.sin(delta_lon / 2)**2
        6371.0 * 2 * Math.atan2(Math.sqrt(haversine), Math.sqrt(1 - haversine))
      end

      def event_summary(segment, genre, venue, location_name)
        category = [ genre, segment ].compact.first
        description = category ? "A local #{category.downcase} event" : "A local event"
        place = venue.present? ? "at #{venue}, near #{location_name}" : "in #{location_name}"
        "#{description} scheduled #{place} for this forecast day."
      end

      def romanian_event_summary(segment, genre, venue, location_name)
        category = [ genre, segment ].compact.first
        description = category ? "un eveniment de tip #{category.downcase}" : "un eveniment local"
        place = venue.present? ? "la #{venue}, în apropiere de #{location_name}" : "în #{location_name}"
        "#{description.capitalize}, programat #{place} pentru această zi."
      end

      def preferred_image(images)
        candidates = Array(images).select { |image| image["ratio"] == "16_9" }
        preferred = candidates.reject { |image| image["fallback"] }.presence || candidates
        preferred.max_by { |image| image["width"].to_i }&.dig("url")
      end

      def price_label(ranges)
        range = Array(ranges).first
        return unless range

        currency = range["currency"].presence
        minimum = range["min"]
        maximum = range["max"]
        return unless currency && minimum

        minimum == maximum ? "#{minimum} #{currency}" : "#{minimum}–#{maximum} #{currency}"
      end
    end
  end
end
