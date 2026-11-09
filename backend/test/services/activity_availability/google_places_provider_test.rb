require "test_helper"

class ActivityAvailability::GooglePlacesProviderTest < ActiveSupport::TestCase
  class FakeClient
    attr_reader :request

    def initialize(payload)
      @payload = payload
    end

    def post_json(uri, body:, headers:)
      @request = { uri:, body:, headers: }
      @payload
    end
  end

  class FixedClock
    def self.current = Time.zone.parse("2026-10-01 09:00:00")
  end

  setup do
    @location = Location.new(
      id: 1,
      name: "Iași",
      country_code: "RO",
      latitude: 47.1585,
      longitude: 27.6014,
      timezone: "Europe/Bucharest",
      provider: "test",
      external_id: "iasi"
    )
    @forecast = DailyForecast.new(
      location: @location,
      forecast_date: Date.new(2026, 10, 2)
    )
    @recommendation = Recommendation.new(
      title: "Explore the Palace of Culture",
      venue_name: "Palace of Culture",
      metadata: { "latitude" => 47.1573, "longitude" => 27.5863 }
    )
  end

  test "verifies the selected period against current provider hours" do
    client = FakeClient.new(
      "places" => [
        {
          "displayName" => { "text" => "Palace of Culture" },
          "location" => { "latitude" => 47.15731, "longitude" => 27.58626 },
          "businessStatus" => "OPERATIONAL",
          "googleMapsUri" => "https://maps.google.com/example",
          "currentOpeningHours" => {
            "periods" => [
              {
                "open" => { "date" => { "year" => 2026, "month" => 10, "day" => 2 }, "hour" => 10 },
                "close" => { "date" => { "year" => 2026, "month" => 10, "day" => 2 }, "hour" => 17 }
              }
            ]
          }
        }
      ]
    )
    provider = ActivityAvailability::GooglePlacesProvider.new(
      client:,
      api_key: "test-key",
      endpoint: "https://places.example.test/search",
      clock: FixedClock
    )

    result = provider.check(
      recommendation: @recommendation,
      forecast: @forecast,
      period: "afternoon"
    )

    assert_equal "verified_open", result.status
    assert_equal "google_places", result.provider
    assert_equal "test-key", client.request.dig(:headers, "X-Goog-Api-Key")
    assert_equal 3, client.request.dig(:body, :pageSize)
  end

  test "does not claim a match for a different or distant place" do
    client = FakeClient.new(
      "places" => [
        {
          "displayName" => { "text" => "Palace Hotel" },
          "location" => { "latitude" => 48.1573, "longitude" => 28.5863 }
        }
      ]
    )
    provider = ActivityAvailability::GooglePlacesProvider.new(
      client:,
      api_key: "test-key",
      clock: FixedClock
    )

    result = provider.check(
      recommendation: @recommendation,
      forecast: @forecast,
      period: "afternoon"
    )

    assert_equal "match_uncertain", result.status
  end

  test "rejects a generic subset name even when it is nearby" do
    client = FakeClient.new(
      "places" => [
        {
          "displayName" => { "text" => "Palace" },
          "location" => { "latitude" => 47.15731, "longitude" => 27.58626 }
        }
      ]
    )
    provider = ActivityAvailability::GooglePlacesProvider.new(
      client:,
      api_key: "test-key",
      clock: FixedClock
    )

    result = provider.check(
      recommendation: @recommendation,
      forecast: @forecast,
      period: "afternoon"
    )

    assert_equal "match_uncertain", result.status
  end

  test "requires recommendation coordinates before accepting a match" do
    @recommendation.metadata = {}
    client = FakeClient.new(
      "places" => [
        {
          "displayName" => { "text" => "Palace of Culture" },
          "location" => { "latitude" => 47.15731, "longitude" => 27.58626 }
        }
      ]
    )
    provider = ActivityAvailability::GooglePlacesProvider.new(
      client:,
      api_key: "test-key",
      clock: FixedClock
    )

    result = provider.check(
      recommendation: @recommendation,
      forecast: @forecast,
      period: "afternoon"
    )

    assert_equal "match_uncertain", result.status
  end

  test "reports dates outside the provider's current-hours window" do
    @forecast.forecast_date = Date.new(2026, 10, 10)
    client = FakeClient.new(
      "places" => [
        {
          "displayName" => { "text" => "Palace of Culture" },
          "location" => { "latitude" => 47.15731, "longitude" => 27.58626 },
          "businessStatus" => "OPERATIONAL",
          "currentOpeningHours" => { "periods" => [] }
        }
      ]
    )
    provider = ActivityAvailability::GooglePlacesProvider.new(
      client:,
      api_key: "test-key",
      clock: FixedClock
    )

    result = provider.check(
      recommendation: @recommendation,
      forecast: @forecast,
      period: "morning"
    )

    assert_equal "outside_window", result.status
  end
end
