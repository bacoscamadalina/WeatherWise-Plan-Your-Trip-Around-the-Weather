module Geocoding
  class OpenMeteoProvider < Provider
    ENDPOINT = "https://geocoding-api.open-meteo.com/v1/search"

    def initialize(client: ExternalApi::HttpClient.new, language: ENV.fetch("GEOCODING_LANGUAGE", "en"))
      @client = client
      @language = language
    end

    def search(query:, limit: 5, language: nil)
      payload = @client.get_json(uri(query, limit, language || @language))
      Array(payload["results"]).map do |item|
        Result.new(
          name: item.fetch("name"),
          country_code: item.fetch("country_code").upcase,
          admin_area: item["admin1"],
          latitude: item.fetch("latitude"),
          longitude: item.fetch("longitude"),
          timezone: item.fetch("timezone", "UTC"),
          provider: "open_meteo",
          external_id: item.fetch("id").to_s,
          country_name: item["country"],
          feature_code: item["feature_code"],
          population: item["population"],
          aliases: Array(item["postcodes"])
        )
      end
    end

    private

    def uri(query, limit, language)
      URI(ENDPOINT).tap do |uri|
        uri.query = URI.encode_www_form(
          name: query,
          count: limit.to_i.clamp(1, 100),
          language: language,
          format: "json"
        )
      end
    end
  end
end
