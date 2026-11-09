module Recommendations
  module Discovery
    class PredictHqProvider < Provider
      ENDPOINT = "https://api.predicthq.com/v1/events/"
      CATEGORIES = %w[concerts festivals performing-arts sports community conferences expos].freeze

      def initialize(
        client: ExternalApi::HttpClient.new,
        access_token: ENV["PREDICTHQ_ACCESS_TOKEN"],
        radius_km: ENV.fetch("PREDICTHQ_RADIUS_KM", ENV.fetch("EVENT_RADIUS_KM", 25)).to_i
      )
        @client = client
        @access_token = access_token
        @radius_km = radius_km.clamp(1, 100)
      end

      def name = "predicthq"

      def cache_scope(request:)
        Recommendation.where(provider: name, location: request.location)
          .where("metadata ->> 'event_date' = ?", request.forecast.forecast_date.iso8601)
      end

      def discover(request:)
        raise ExternalApi::Error, "PREDICTHQ_ACCESS_TOKEN is not configured" if @access_token.blank?

        discover_range(
          location: request.location,
          forecasts: [ request.forecast ],
          language: request.preferences[:language]
        )
      end

      def discover_range(location:, forecasts:, language: "en")
        raise ExternalApi::Error, "PREDICTHQ_ACCESS_TOKEN is not configured" if @access_token.blank?
        return [] if forecasts.empty?

        forecasts_by_date = forecasts.index_by(&:forecast_date)
        payload = @client.get_json(
          range_uri(location:, forecasts:),
          headers: { "Authorization" => "Bearer #{@access_token}" }
        )
        Array(payload["results"]).filter_map do |event|
          local_start = parse_local_start(event, location.timezone)
          forecast = forecasts_by_date[local_start&.to_date]
          next unless forecast

          request = Request.new(location:, forecast:, preferences: { language: })
          map(event, request)
        end
      end

      private

      def uri(request)
        range_uri(location: request.location, forecasts: [ request.forecast ])
      end

      def range_uri(location:, forecasts:)
        dates = forecasts.map(&:forecast_date).minmax

        URI(ENDPOINT).tap do |uri|
          uri.query = URI.encode_www_form(
            "active.gte" => dates.first.iso8601,
            "active.lte" => dates.last.iso8601,
            "active.tz" => location.timezone.presence || "UTC",
            within: "#{radius_for(location)}km@#{location.latitude},#{location.longitude}",
            country: location.country_code,
            category: CATEGORIES.join(","),
            state: "active,predicted",
            "brand_unsafe.exclude" => "true",
            sort: "start,local_rank,rank",
            limit: forecasts.one? ? 50 : 100
          )
        end
      end

      def map(event, request)
        return unless event["id"].present? && event["title"].present?
        return if event["state"] == "deleted"

        local_start = parse_local_start(event, request.location.timezone)
        return unless local_start&.to_date == request.forecast.forecast_date

        longitude, latitude = coordinates(event)
        distance = distance_km(request.location, latitude, longitude)
        radius = radius_for(request.location)
        return if distance && distance > radius

        category = event["category"].to_s
        venue = venue_name(event)
        address = event.dig("geo", "address") || {}

        CatalogItem.new(
          location: request.location,
          recommendation_type: "event",
          title: event["title"],
          summary: event_summary(category, venue, request.location.name),
          venue_name: venue,
          indoor: true,
          provider: name,
          external_id: "#{location_cache_key(request.location)}:#{event.fetch('id')}",
          url: nil,
          genres: [ category.tr("-", " ") ].reject(&:blank?),
          tags: [ "event", "live", "setting-unverified", category ].reject(&:blank?),
          weather_classes: %w[clear cloudy rain snow storm fog],
          metadata: {
            event_date: local_start.to_date.iso8601,
            event_time: known_time(event, local_start),
            event_timezone: event["timezone"],
            event_status: event["state"],
            provider_event_id: event.fetch("id"),
            venue_city: address["locality"],
            venue_address: address["formatted_address"],
            latitude:,
            longitude:,
            distance_km: distance&.round(1),
            search_radius_km: radius,
            event_category: category,
            provider_rank: event["local_rank"] || event["rank"],
            predicted_attendance: event["phq_attendance"],
            setting: "unknown",
            translations: {
              ro: { summary: romanian_event_summary(category, venue, request.location.name) }
            }
          }.compact
        )
      end

      def parse_local_start(event, fallback_timezone)
        return Time.zone.parse(event["start_local"]) if event["start_local"].present?
        return unless event["start"].present?

        parsed = Time.iso8601(event["start"])
        zone = ActiveSupport::TimeZone[event["timezone"].presence || fallback_timezone] || ActiveSupport::TimeZone["UTC"]
        parsed.in_time_zone(zone)
      rescue ArgumentError
        nil
      end

      def known_time(event, local_start)
        return if event["start_local"].to_s.match?(/T00:00:00/) && event["timezone"].present?

        local_start.strftime("%H:%M:%S")
      end

      def coordinates(event)
        geometry = event.dig("geo", "geometry")
        values = geometry["coordinates"] if geometry.is_a?(Hash) && geometry["type"] == "Point"
        values ||= event["location"]
        return [ nil, nil ] unless values.is_a?(Array) && values.length >= 2

        [ values[0].to_f, values[1].to_f ]
      end

      def venue_name(event)
        Array(event["entities"]).find { |entity| entity["type"] == "venue" }&.dig("name")
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
        return unless latitude && longitude

        lat1 = location.latitude.to_f * Math::PI / 180
        lat2 = latitude.to_f * Math::PI / 180
        delta_lat = lat2 - lat1
        delta_lon = (longitude.to_f - location.longitude.to_f) * Math::PI / 180
        haversine = Math.sin(delta_lat / 2)**2 + Math.cos(lat1) * Math.cos(lat2) * Math.sin(delta_lon / 2)**2
        6371.0 * 2 * Math.atan2(Math.sqrt(haversine), Math.sqrt(1 - haversine))
      end

      def event_summary(category, venue, location_name)
        kind = category.present? ? category.tr("-", " ") : "public"
        place = venue.present? ? "at #{venue}, near #{location_name}" : "near #{location_name}"
        "A #{kind} event scheduled #{place} for this forecast day."
      end

      def romanian_event_summary(category, venue, location_name)
        kind = category.present? ? category.tr("-", " ") : "public"
        place = venue.present? ? "la #{venue}, în apropiere de #{location_name}" : "în apropiere de #{location_name}"
        "Un eveniment de tip #{kind}, programat #{place} pentru această zi."
      end
    end
  end
end
