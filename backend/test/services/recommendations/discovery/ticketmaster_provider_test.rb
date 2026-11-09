require "test_helper"

class Recommendations::Discovery::TicketmasterProviderTest < ActiveSupport::TestCase
  class FakeClient
    attr_reader :uri

    def get_json(uri, headers: {})
      @uri = uri
      {
        "_embedded" => {
          "events" => [
            {
              "id" => "event-42",
              "name" => "Iași Jazz Evening",
              "url" => "https://example.test/events/42",
              "dates" => {
                "start" => { "localDate" => "2026-10-02", "localTime" => "19:30:00" },
                "timezone" => "Europe/Bucharest",
                "status" => { "code" => "onsale" }
              },
              "classifications" => [
                { "segment" => { "name" => "Music" }, "genre" => { "name" => "Jazz" } }
              ],
              "priceRanges" => [ { "currency" => "RON", "min" => 80, "max" => 120 } ],
              "images" => [ { "ratio" => "16_9", "width" => 1024, "url" => "https://example.test/event.jpg" } ],
              "_embedded" => {
                "venues" => [
                  {
                    "name" => "Test Hall",
                    "location" => { "latitude" => "47.16", "longitude" => "27.60" }
                  }
                ]
              }
            }
          ]
        }
      }
    end
  end

  test "searches by geohash and maps date-scoped events without claiming a venue setting" do
    client = FakeClient.new
    location = Location.new(
      name: "Iași", country_code: "RO", latitude: 47.1585, longitude: 27.6014,
      timezone: "Europe/Bucharest"
    )
    forecast = DailyForecast.new(forecast_date: Date.new(2026, 10, 2))
    request = Recommendations::Request.new(location:, forecast:, preferences: {})

    item = Recommendations::Discovery::TicketmasterProvider.new(
      client:, api_key: "test-key", radius_km: 30
    ).discover(request:).first

    query = URI.decode_www_form(client.uri.query).to_h
    assert_equal "test-key", query.fetch("apikey")
    assert_equal 9, query.fetch("geoPoint").length
    assert_nil query["latlong"]
    assert_equal "30", query.fetch("radius")
    assert_equal "RO", query.fetch("countryCode")
    assert_equal "en-ro,en,*", query.fetch("locale")
    assert_equal "distance,date,asc", query.fetch("sort")
    assert_equal "event", item.recommendation_type
    assert_equal "Iași Jazz Evening", item.title
    assert_match(/:event-42\z/, item.external_id)
    assert_equal "unknown", item.metadata[:setting]
    assert_equal "2026-10-02", item.metadata[:event_date]
    assert_equal "event-42", item.metadata[:provider_event_id]
    assert_in_delta 0.2, item.metadata[:distance_km], 0.2
    assert_equal "80–120 RON", item.metadata[:price_label]
    assert_includes item.metadata.dig(:translations, :ro, :summary), "Iași"
  end

  test "expands the radius for a village and keeps event ids local to each place" do
    village = Location.new(
      name: "Miroslava", country_code: "RO", latitude: 47.14, longitude: 27.51,
      timezone: "Europe/Bucharest", provider: "open_meteo", external_id: "village-1",
      feature_code: "PPL", population: 12_000
    )
    forecast = DailyForecast.new(forecast_date: Date.new(2026, 10, 2))
    request = Recommendations::Request.new(location: village, forecast:, preferences: { language: "ro" })
    client = FakeClient.new

    item = Recommendations::Discovery::TicketmasterProvider.new(
      client:, api_key: "test-key", radius_km: 30
    ).discover(request:).first

    query = URI.decode_www_form(client.uri.query).to_h
    assert_equal "60", query.fetch("radius")
    assert_equal "ro-ro,ro,*", query.fetch("locale")
    refute_equal "event-42", item.external_id
    assert_includes item.metadata.dig(:translations, :ro, :summary), "Test Hall"
  end

  test "does not return canceled events" do
    client = Class.new(FakeClient) do
      def get_json(uri, headers: {})
        super.tap do |payload|
          payload.dig("_embedded", "events", 0, "dates", "status")["code"] = "canceled"
        end
      end
    end.new
    request = Recommendations::Request.new(
      location: Location.new(name: "Iași", country_code: "RO", latitude: 47.1585, longitude: 27.6014, timezone: "Europe/Bucharest"),
      forecast: DailyForecast.new(forecast_date: Date.new(2026, 10, 2)), preferences: {}
    )

    items = Recommendations::Discovery::TicketmasterProvider.new(
      client:, api_key: "test-key"
    ).discover(request:)

    assert_empty items
  end

  test "requires an API key" do
    request = Recommendations::Request.new(
      location: Location.new(latitude: 47, longitude: 27),
      forecast: DailyForecast.new(forecast_date: Date.current),
      preferences: {}
    )

    assert_raises(ExternalApi::Error) do
      Recommendations::Discovery::TicketmasterProvider.new(
        client: FakeClient.new,
        api_key: nil
      ).discover(request:)
    end
  end
end
