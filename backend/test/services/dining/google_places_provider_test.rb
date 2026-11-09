require "test_helper"

class Dining::GooglePlacesProviderTest < ActiveSupport::TestCase
  FakeClient = Struct.new(:payload, :request) do
    def post_json(uri, body:, headers:)
      self.request = { uri:, body:, headers: }
      payload
    end
  end

  test "keeps only open venues with trustworthy ratings" do
    client = FakeClient.new({
      "places" => [
        place("great", 4.7, 312),
        place("thin", 4.9, 2),
        place("low", 3.9, 900),
        place("closed", 4.8, 250, status: "CLOSED_TEMPORARILY"),
        place("unknown", 4.8, 250, status: "BUSINESS_STATUS_UNSPECIFIED"),
        place("far", 4.9, 800, latitude: 48.2)
      ]
    })
    provider = Dining::GooglePlacesProvider.new(client:, api_key: "key")

    venues = provider.search(location:, meal: "dinner", radius_km: 50, language: "ro")

    assert_equal [ "great" ], venues.map(&:external_id)
    assert_equal 4.7, venues.first.rating
    assert_equal 312, venues.first.rating_count
    assert_equal 50_000, client.request.dig(:body, :locationBias, :circle, :radius)
    assert_includes client.request.dig(:headers, "X-Goog-FieldMask"), "places.userRatingCount"
  end

  test "uses dietary intent and supported price filters" do
    client = FakeClient.new({ "places" => [] })
    provider = Dining::GooglePlacesProvider.new(client:, api_key: "key")

    provider.search(
      location:, meal: "lunch", radius_km: 20, language: "ro",
      preferences: { "dietary" => %w[vegan gluten_free], "budget" => "moderate" }
    )

    body = client.request.fetch(:body)
    assert_match(/vegan gluten-free lunch restaurant/, body.fetch(:textQuery))
    assert_equal %w[PRICE_LEVEL_INEXPENSIVE PRICE_LEVEL_MODERATE], body.fetch(:priceLevels)
    assert_equal 4.0, body.fetch(:minRating)
  end

  private

  def location
    Location.new(
      name: "Iași", country_name: "România", country_code: "RO",
      latitude: 47.1585, longitude: 27.6014, timezone: "Europe/Bucharest",
      provider: "test", external_id: "dining-iasi"
    )
  end

  def place(id, rating, count, status: "OPERATIONAL", latitude: 47.16)
    {
      "id" => id,
      "displayName" => { "text" => "Venue #{id}" },
      "formattedAddress" => "Iași",
      "location" => { "latitude" => latitude, "longitude" => 27.60 },
      "rating" => rating,
      "userRatingCount" => count,
      "businessStatus" => status,
      "googleMapsUri" => "https://maps.google.com/?q=#{id}"
    }
  end
end
