module Routing
  class GoogleRoutesProvider < Provider
    ENDPOINT = "https://routes.googleapis.com/directions/v2:computeRoutes"
    TRAVEL_MODES = {
      "car" => "DRIVE",
      "walking" => "WALK",
      "bicycle" => "BICYCLE",
      "public_transport" => "TRANSIT"
    }.freeze

    def initialize(
      client: ExternalApi::HttpClient.new,
      api_key: ENV["GOOGLE_ROUTES_API_KEY"],
      endpoint: ENV.fetch("GOOGLE_ROUTES_API_URL", ENDPOINT),
      cache: Rails.cache
    )
      @client = client
      @api_key = api_key
      @endpoint = endpoint
      @cache = cache
    end

    def live? = @api_key.present?

    def route(origin:, destination:, transport_mode:, departure_at: nil, arrival_at: nil, language: "en")
      return unless live?

      mode = TRAVEL_MODES.fetch(transport_mode.to_s)
      payload = @cache.fetch(
        cache_key(origin, destination, mode, departure_at, arrival_at),
        expires_in: ENV.fetch("ROUTE_CACHE_TTL_HOURS", 24).to_i.clamp(1, 168).hours
      ) do
        @client.post_json(
          URI(@endpoint),
          body: request_body(origin, destination, mode, departure_at, arrival_at, language),
          headers: {
            "Content-Type" => "application/json",
            "X-Goog-Api-Key" => @api_key,
            "X-Goog-FieldMask" => "routes.duration,routes.distanceMeters"
          }
        )
      end
      map(payload, transport_mode)
    end

    private

    def request_body(origin, destination, mode, departure_at, arrival_at, language)
      {
        origin: waypoint(origin),
        destination: waypoint(destination),
        travelMode: mode,
        computeAlternativeRoutes: false,
        languageCode: language.to_s.start_with?("ro") ? "ro-RO" : "en-US",
        units: "METRIC",
        **(mode == "DRIVE" ? { routingPreference: "TRAFFIC_UNAWARE" } : {}),
        **transit_reference(mode, departure_at, arrival_at)
      }
    end

    def transit_reference(mode, departure_at, arrival_at)
      return {} unless mode == "TRANSIT"
      return { departureTime: departure_at.iso8601 } if departure_at
      return { arrivalTime: arrival_at.iso8601 } if arrival_at

      {}
    end

    def waypoint(point)
      {
        location: {
          latLng: {
            latitude: point.fetch(:latitude).to_f,
            longitude: point.fetch(:longitude).to_f
          }
        }
      }
    end

    def map(payload, transport_mode)
      route = Array(payload["routes"]).first
      return unless route

      seconds = route.fetch("duration").to_s.delete_suffix("s").to_f
      distance_meters = route.fetch("distanceMeters").to_f
      Route.new(
        duration_minutes: (seconds / 60.0).ceil,
        distance_km: (distance_meters / 1_000.0).round(1),
        provider: "google_routes",
        transport_mode:
      )
    rescue KeyError, TypeError
      raise ExternalApi::Error, "Routing provider returned an incomplete route"
    end

    def cache_key(origin, destination, mode, departure_at, arrival_at)
      coordinates = [ origin, destination ].flat_map do |point|
        [ point.fetch(:latitude).to_f.round(5), point.fetch(:longitude).to_f.round(5) ]
      end
      transit_reference = if mode == "TRANSIT"
        time = departure_at || arrival_at
        bucket = time && "#{time.strftime('%Y%m%d-%H')}#{format('%02d', (time.min / 5) * 5)}"
        [ departure_at ? "depart" : "arrive", bucket ].compact.join("-")
      end
      [ "route", "google", mode, *coordinates, transit_reference ].compact.join(":")
    end
  end
end
