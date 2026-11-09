module Dining
  class GooglePlacesProvider < Provider
    ENDPOINT = "https://places.googleapis.com/v1/places:searchText"
    MINIMUM_RATING = 4.0
    MINIMUM_RATING_COUNT = 10

    def initialize(
      client: ExternalApi::HttpClient.new,
      api_key: ENV["GOOGLE_PLACES_API_KEY"],
      endpoint: ENV.fetch("GOOGLE_PLACES_API_URL", ENDPOINT)
    )
      @client = client
      @api_key = api_key
      @endpoint = endpoint
    end

    def live? = @api_key.present?

    def search(location:, meal:, radius_km:, language:, preferences: {})
      return [] unless live?

      payload = @client.post_json(
        URI(@endpoint),
        body: request_body(location, meal, radius_km, language, preferences),
        headers: {
          "Content-Type" => "application/json",
          "X-Goog-Api-Key" => @api_key,
          "X-Goog-FieldMask" => field_mask
        }
      )
      Array(payload["places"]).filter_map { |place| map(place, location) }
        .select do |venue|
          venue.distance_km <= radius_km.to_f.clamp(1, 50) &&
            venue.rating >= MINIMUM_RATING &&
            venue.rating_count >= MINIMUM_RATING_COUNT
        end
        .sort_by { |venue| [ -venue.rating, -venue.rating_count, venue.distance_km ] }
    end

    private

    def request_body(location, meal, radius_km, language, preferences)
      query = case meal
      when "breakfast" then "breakfast cafe"
      when "lunch" then "lunch restaurant"
      else "dinner restaurant"
      end
      dietary = Array(preferences["dietary"] || preferences[:dietary])
      dietary_query = dietary.filter_map do |value|
        { "vegetarian" => "vegetarian", "vegan" => "vegan", "gluten_free" => "gluten-free" }[value.to_s]
      end.join(" ")
      budget = (preferences["budget"] || preferences[:budget]).to_s
      price_levels = case budget
      when "value" then %w[PRICE_LEVEL_INEXPENSIVE]
      when "moderate" then %w[PRICE_LEVEL_INEXPENSIVE PRICE_LEVEL_MODERATE]
      end
      {
        textQuery: [ dietary_query.presence, query, "in #{location.display_name}" ].compact.join(" "),
        pageSize: 20,
        languageCode: language,
        rankPreference: "RELEVANCE",
        minRating: MINIMUM_RATING,
        **(price_levels ? { priceLevels: price_levels } : {}),
        locationBias: {
          circle: {
            center: { latitude: location.latitude.to_f, longitude: location.longitude.to_f },
            radius: (radius_km.to_f.clamp(1, 50) * 1_000).round
          }
        }
      }
    end

    def field_mask
      %w[
        places.id places.displayName places.formattedAddress places.location
        places.rating places.userRatingCount places.priceLevel places.types
        places.googleMapsUri places.businessStatus
      ].join(",")
    end

    def map(place, location)
      return unless place["businessStatus"] == "OPERATIONAL"

      latitude = place.dig("location", "latitude")
      longitude = place.dig("location", "longitude")
      rating = Float(place["rating"], exception: false)
      rating_count = Integer(place["userRatingCount"], exception: false)
      return unless latitude && longitude && rating && rating_count

      Venue.new(
        external_id: place.fetch("id"),
        name: place.dig("displayName", "text").presence || place.fetch("id"),
        address: place["formattedAddress"],
        latitude: latitude.to_f,
        longitude: longitude.to_f,
        rating:,
        rating_count:,
        price_level: place["priceLevel"],
        types: Array(place["types"]),
        url: place["googleMapsUri"],
        provider: "google_places",
        distance_km: distance(location.latitude.to_f, location.longitude.to_f, latitude.to_f, longitude.to_f).round(1)
      )
    end

    def distance(latitude_a, longitude_a, latitude_b, longitude_b)
      radius = 6_371.0
      latitude_delta = radians(latitude_b - latitude_a)
      longitude_delta = radians(longitude_b - longitude_a)
      value = Math.sin(latitude_delta / 2)**2 +
        Math.cos(radians(latitude_a)) * Math.cos(radians(latitude_b)) * Math.sin(longitude_delta / 2)**2
      radius * 2 * Math.atan2(Math.sqrt(value), Math.sqrt(1 - value))
    end

    def radians(value) = value * Math::PI / 180
  end
end
