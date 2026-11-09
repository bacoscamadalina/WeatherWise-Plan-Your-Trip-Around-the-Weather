module Geocoding
  class MockProvider < Provider
    LOCATIONS = [
      Result.new(
        name: "Iași",
        country_code: "RO",
        admin_area: "Iași County",
        latitude: 47.1585,
        longitude: 27.6014,
        timezone: "Europe/Bucharest",
        provider: "mock",
        external_id: "iasi-ro",
        country_name: "Romania",
        feature_code: "PPLA",
        population: 271_692,
        aliases: [ "Iasi", "Jassy", "700000" ]
      )
    ].freeze

    def search(query:, limit: 5, language: nil)
      normalized = normalize(query)
      LOCATIONS.select do |location|
        candidates = [ location.name, *location.aliases ].map { |value| normalize(value) }
        candidates.any? { |candidate| candidate.include?(normalized) || normalized.include?(candidate) }
      end.first(limit)
    end

    private

    def normalize(value)
      value.to_s.unicode_normalize(:nfkd).gsub(/\p{Mn}/, "").downcase.strip
    end
  end
end
