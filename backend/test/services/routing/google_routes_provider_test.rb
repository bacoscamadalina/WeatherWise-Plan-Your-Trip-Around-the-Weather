require "test_helper"

class Routing::GoogleRoutesProviderTest < ActiveSupport::TestCase
  FakeClient = Struct.new(:payload, :calls) do
    def post_json(uri, body:, headers:)
      calls << { uri:, body:, headers: }
      payload
    end
  end

  test "maps a Google route and sends the selected transport mode" do
    client = FakeClient.new({
      "routes" => [ { "duration" => "754s", "distanceMeters" => 8_450 } ]
    }, [])
    provider = Routing::GoogleRoutesProvider.new(
      client:, api_key: "routes-key", cache: ActiveSupport::Cache::MemoryStore.new
    )

    route = provider.route(
      origin: { latitude: 47.1585, longitude: 27.6014 },
      destination: { latitude: 47.1747, longitude: 27.5719 },
      transport_mode: "car",
      language: "ro"
    )

    assert_equal 13, route.duration_minutes
    assert_equal 8.5, route.distance_km
    assert_equal "google_routes", route.provider
    assert_equal "DRIVE", client.calls.first.dig(:body, :travelMode)
    assert_equal "TRAFFIC_UNAWARE", client.calls.first.dig(:body, :routingPreference)
    assert_equal "ro-RO", client.calls.first.dig(:body, :languageCode)
    assert_equal "routes.duration,routes.distanceMeters",
      client.calls.first.dig(:headers, "X-Goog-FieldMask")
  end

  test "returns no route when credentials are missing" do
    client = FakeClient.new({}, [])
    provider = Routing::GoogleRoutesProvider.new(
      client:, api_key: nil, cache: ActiveSupport::Cache::MemoryStore.new
    )

    assert_nil provider.route(
      origin: { latitude: 47.1, longitude: 27.6 },
      destination: { latitude: 47.2, longitude: 27.5 },
      transport_mode: "walking"
    )
    assert_empty client.calls
  end

  test "uses arrival time for the first transit leg" do
    client = FakeClient.new({
      "routes" => [ { "duration" => "900s", "distanceMeters" => 4_000 } ]
    }, [])
    provider = Routing::GoogleRoutesProvider.new(
      client:, api_key: "routes-key", cache: ActiveSupport::Cache::MemoryStore.new
    )
    arrival = Time.iso8601("2026-10-08T10:00:00+03:00")

    provider.route(
      origin: { latitude: 47.1585, longitude: 27.6014 },
      destination: { latitude: 47.1747, longitude: 27.5719 },
      transport_mode: "public_transport",
      arrival_at: arrival
    )

    assert_equal "TRANSIT", client.calls.first.dig(:body, :travelMode)
    assert_equal arrival.iso8601, client.calls.first.dig(:body, :arrivalTime)
    assert_nil client.calls.first.dig(:body, :departureTime)
  end

  test "caches transit routes by service date and five minute bucket" do
    client = FakeClient.new({
      "routes" => [ { "duration" => "900s", "distanceMeters" => 4_000 } ]
    }, [])
    provider = Routing::GoogleRoutesProvider.new(
      client:, api_key: "routes-key", cache: ActiveSupport::Cache::MemoryStore.new
    )
    origin = { latitude: 47.1585, longitude: 27.6014 }
    destination = { latitude: 47.1747, longitude: 27.5719 }

    [
      "2026-10-08T09:01:00+03:00",
      "2026-10-08T09:04:00+03:00",
      "2026-10-08T09:06:00+03:00",
      "2026-10-15T09:01:00+03:00"
    ].each do |value|
      provider.route(
        origin:, destination:, transport_mode: "public_transport",
        departure_at: Time.iso8601(value)
      )
    end

    assert_equal 3, client.calls.size
  end
end
