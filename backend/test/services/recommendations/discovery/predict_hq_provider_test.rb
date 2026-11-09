require "test_helper"

class Recommendations::Discovery::PredictHqProviderTest < ActiveSupport::TestCase
  class FakeClient
    attr_reader :uri, :headers

    def get_json(uri, headers: {})
      @uri = uri
      @headers = headers
      {
        "results" => [
          {
            "id" => "phq-42",
            "title" => "Iași Autumn Festival",
            "category" => "festivals",
            "state" => "active",
            "start" => "2026-10-02T16:30:00Z",
            "start_local" => "2026-10-02T19:30:00",
            "timezone" => "Europe/Bucharest",
            "rank" => 66,
            "local_rank" => 74,
            "phq_attendance" => 2500,
            "entities" => [ { "type" => "venue", "name" => "Palas Garden" } ],
            "geo" => {
              "geometry" => { "type" => "Point", "coordinates" => [ 27.6000, 47.1600 ] },
              "address" => { "locality" => "Iași", "formatted_address" => "Palas, Iași" }
            }
          }
        ]
      }
    end
  end

  test "searches globally by coordinate radius and maps a local event" do
    client = FakeClient.new
    request = Recommendations::Request.new(
      location: Location.new(
        name: "Iași", country_code: "RO", latitude: 47.1585, longitude: 27.6014,
        timezone: "Europe/Bucharest", provider: "open_meteo", external_id: "iasi"
      ),
      forecast: DailyForecast.new(forecast_date: Date.new(2026, 10, 2)),
      preferences: { language: "ro" }
    )

    item = Recommendations::Discovery::PredictHqProvider.new(
      client:, access_token: "test-token", radius_km: 30
    ).discover(request:).first

    query = URI.decode_www_form(client.uri.query).to_h
    assert_equal "Bearer test-token", client.headers.fetch("Authorization")
    assert_equal "2026-10-02", query.fetch("active.gte")
    assert_equal "2026-10-02", query.fetch("active.lte")
    assert_equal "Europe/Bucharest", query.fetch("active.tz")
    assert_equal "30km@47.1585,27.6014", query.fetch("within")
    assert_equal "RO", query.fetch("country")
    assert_includes query.fetch("category"), "performing-arts"
    assert_equal "Iași Autumn Festival", item.title
    assert_equal "Palas Garden", item.venue_name
    assert_equal "2026-10-02", item.metadata[:event_date]
    assert_equal "19:30:00", item.metadata[:event_time]
    assert_equal 2500, item.metadata[:predicted_attendance]
    assert_in_delta 0.2, item.metadata[:distance_km], 0.2
    assert_includes item.metadata.dig(:translations, :ro, :summary), "Iași"
  end

  test "rejects results outside the selected local day" do
    client = Class.new(FakeClient) do
      def get_json(uri, headers: {})
        super.tap { |payload| payload.fetch("results").first["start_local"] = "2026-10-03T00:30:00" }
      end
    end.new
    request = Recommendations::Request.new(
      location: Location.new(name: "Iași", country_code: "RO", latitude: 47.1585, longitude: 27.6014, timezone: "Europe/Bucharest"),
      forecast: DailyForecast.new(forecast_date: Date.new(2026, 10, 2)), preferences: {}
    )

    items = Recommendations::Discovery::PredictHqProvider.new(
      client:, access_token: "test-token"
    ).discover(request:)

    assert_empty items
  end

  test "requires an access token" do
    request = Recommendations::Request.new(
      location: Location.new(latitude: 47, longitude: 27),
      forecast: DailyForecast.new(forecast_date: Date.current), preferences: {}
    )

    assert_raises(ExternalApi::Error) do
      Recommendations::Discovery::PredictHqProvider.new(
        client: FakeClient.new, access_token: nil
      ).discover(request:)
    end
  end
end
