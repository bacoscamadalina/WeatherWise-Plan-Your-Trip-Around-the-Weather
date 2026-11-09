module Showtimes
  class MovieGluProvider < Provider
    ENDPOINT = "https://api-gate2.movieglu.com/"

    def initialize(
      client: ExternalApi::HttpClient.new,
      endpoint: ENV.fetch("MOVIEGLU_API_URL", ENDPOINT),
      credentials: default_credentials,
      clock: Time
    )
      @client = client
      @endpoint = endpoint
      @credentials = credentials
      @clock = clock
    end

    def name = "movieglu"

    def for_date(request:)
      ensure_configured!
      films = Array(@client.get_json(uri("filmsNowShowing/", n: request.limit), headers: headers(request.location))["films"])

      films.first(request.limit).flat_map do |film|
        showtimes_for_film(film, request)
      rescue ExternalApi::Error => error
        Rails.logger.warn("MovieGlu showtimes unavailable for film #{film['film_id']}: #{error.message}")
        []
      end.first(request.limit * 8)
    end

    def booking_link(request:)
      ensure_configured!
      payload = @client.get_json(
        uri(
          "purchaseConfirmation/",
          cinema_id: request.cinema_id,
          film_id: request.film_id,
          date: request.date.iso8601,
          time: request.time
        ),
        headers: headers(request.location)
      )
      payload["url"].presence || payload["purchase_url"].presence
    end

    private

    def self.default_credentials
      {
        client: ENV["MOVIEGLU_CLIENT"],
        api_key: ENV["MOVIEGLU_API_KEY"],
        authorization: ENV["MOVIEGLU_AUTHORIZATION"],
        territory: ENV["MOVIEGLU_TERRITORY"],
        api_version: ENV.fetch("MOVIEGLU_API_VERSION", "v200")
      }
    end

    def default_credentials = self.class.default_credentials

    def ensure_configured!
      missing = @credentials.select { |_, value| value.blank? }.keys
      return if missing.empty?

      raise ExternalApi::Error, "MovieGlu credentials are incomplete: #{missing.join(', ')}"
    end

    def showtimes_for_film(film, request)
      payload = @client.get_json(
        uri("filmShowTimes/", film_id: film.fetch("film_id"), date: request.date.iso8601, n: request.limit),
        headers: headers(request.location)
      )

      Array(payload["cinemas"]).flat_map do |cinema|
        listings_for(cinema, film, request.date)
      end
    end

    def listings_for(cinema, film, date)
      cinema.fetch("showings", {}).flat_map do |format, showing|
        Array(showing["times"]).map do |time|
          Listing.new(
            id: [ film["film_id"], cinema["cinema_id"], date, time["start_time"], format ].join(":"),
            film_id: film["film_id"].to_s,
            film_title: film["film_name"],
            cinema_id: cinema["cinema_id"].to_s,
            cinema_name: cinema["cinema_name"],
            date:,
            format:,
            start_time: time["start_time"],
            end_time: time["end_time"],
            distance_km: miles_to_km(cinema["distance"]),
            image_url: film["film_image"]
          )
        end
      end
    end

    def headers(location)
      {
        "client" => @credentials.fetch(:client),
        "x-api-key" => @credentials.fetch(:api_key),
        "authorization" => @credentials.fetch(:authorization),
        "territory" => @credentials.fetch(:territory),
        "api-version" => @credentials.fetch(:api_version),
        "geolocation" => "#{location.latitude.to_f.round(6)};#{location.longitude.to_f.round(6)}",
        "device-datetime" => @clock.current.utc.iso8601(3),
        "app-platform" => "WeatherWise Server"
      }
    end

    def uri(path, **parameters)
      URI.join(@endpoint, path).tap do |uri|
        uri.query = URI.encode_www_form(parameters)
      end
    end

    def miles_to_km(miles)
      (miles.to_f * 1.60934).round(1) if miles
    end
  end
end
