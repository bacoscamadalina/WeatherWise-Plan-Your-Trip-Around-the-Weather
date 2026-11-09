require "test_helper"

class Recommendations::Discovery::OverpassProviderTest < ActiveSupport::TestCase
  class FakeClient
    attr_reader :uri, :uris

    def get_json(uri, headers: {})
      @uri = uri
      (@uris ||= []) << uri
      {
        "elements" => [
          {
            "type" => "node", "id" => 101, "lat" => 47.16, "lon" => 27.60,
            "tags" => { "name" => "Test Museum", "tourism" => "museum", "opening_hours" => "Tu-Su 10:00-17:00" }
          },
          {
            "type" => "way", "id" => 202,
            "center" => { "lat" => 47.17, "lon" => 27.61 },
            "tags" => { "name" => "Test Park", "leisure" => "park" }
          }
        ]
      }
    end
  end

  class FakeImageResolver
    def resolve(elements)
      {
        "node/101" => Recommendations::Discovery::WikimediaImageResolver::Image.new(
          url: "https://upload.wikimedia.org/museum.jpg",
          attribution: "Photographer · CC BY-SA 4.0 · Wikimedia Commons",
          source_url: "https://commons.wikimedia.org/wiki/File:Museum.jpg"
        )
      }
    end
  end

  class FakeMountainClient
    attr_reader :uri, :uris

    def get_json(uri, headers: {})
      @uri = uri
      (@uris ||= []) << uri
      {
        "elements" => [
          {
            "type" => "node", "id" => 301, "lat" => 46.947, "lon" => 25.945,
            "tags" => { "name" => "Vârful Toaca", "natural" => "peak", "ele" => "1904" }
          },
          {
            "type" => "relation", "id" => 302,
            "center" => { "lat" => 47.30, "lon" => 26.20 },
            "members" => [
              {
                "type" => "way", "ref" => 9001,
                "geometry" => [
                  { "lat" => 46.94, "lon" => 25.93 },
                  { "lat" => 46.945, "lon" => 25.94 }
                ]
              }
            ],
            "tags" => {
              "name" => "Traseu spre Toaca", "type" => "route", "route" => "hiking",
              "distance" => "8.5 km", "sac_scale" => "mountain_hiking",
              "from" => "Durău", "to" => "Vârful Toaca", "duration" => "03:30",
              "ascent" => "780 m", "descent" => "120", "roundtrip" => "no",
              "network" => "rwn", "ref" => "bandă roșie",
              "osmc:symbol" => "red:white:red_bar", "operator" => "Salvamont Neamț",
              "website" => "https://example.test/toaca"
            }
          },
          {
            "type" => "node", "id" => 303, "lat" => 46.93, "lon" => 25.94,
            "tags" => { "name" => "Lumea Pierdută", "tourism" => "viewpoint" }
          },
          {
            "type" => "node", "id" => 304, "lat" => 46.92, "lon" => 25.95,
            "tags" => { "name" => "Cabana Dochia", "tourism" => "alpine_hut" }
          }
        ]
      }
    end
  end

  setup do
    @location = Location.new(name: "Iași", country_code: "RO", latitude: 47.1585, longitude: 27.6014)
    @request = Recommendations::Request.new(location: @location, forecast: nil, preferences: {})
  end

  test "maps nearby indoor and outdoor places with distance and source links" do
    client = FakeClient.new
    items = Recommendations::Discovery::OverpassProvider.new(
      client:,
      radius_meters: 5_000,
      image_resolver: FakeImageResolver.new
    ).discover(request: @request)

    assert_equal [ "Test Museum", "Test Park" ], items.map(&:title)
    assert items.first.indoor
    assert_not items.second.indoor
    assert_equal "Tu-Su 10:00-17:00", items.first.metadata[:opening_hours]
    assert_operator items.first.metadata[:distance_km], :>=, 0
    assert_equal "https://www.openstreetmap.org/node/101", items.first.url
    assert_equal "en:47.1585,27.6014:node/101", items.first.external_id
    assert_equal "https://upload.wikimedia.org/museum.jpg", items.first.metadata[:image_url]
    assert_includes items.first.metadata[:image_attribution], "CC BY-SA 4.0"
    assert_nil items.second.metadata[:image_url]

    queries = client.uris.map { |uri| URI.decode_www_form(uri.query).to_h.fetch("data") }
    assert queries.any? { |query| query.include?('["tourism"~') }
    assert queries.none? { |query| query.include?("around:") }
  end

  test "discovers peaks and mapped hiking routes with trail metadata" do
    location = Location.new(name: "Bicaz", country_code: "RO", latitude: 46.91, longitude: 26.09)
    request = Recommendations::Request.new(
      location:, forecast: nil, preferences: { language: "ro" }
    )
    client = FakeMountainClient.new
    items = Recommendations::Discovery::OverpassProvider.new(
      client:, radius_meters: 20_000, image_resolver: FakeImageResolver.new
    ).discover(request:)

    peak = items.find { |item| item.title == "Vârful Toaca" }
    trail = items.find { |item| item.title == "Traseu spre Toaca" }
    assert_equal 1904, peak.metadata[:elevation_m]
    assert_equal "peak", peak.metadata[:activity_category]
    assert_equal "dry_daylight", peak.metadata[:weather_sensitivity]
    assert_includes peak.tags, "summit"
    assert_equal 8.5, trail.metadata[:route_distance_km]
    assert_equal "trail", trail.metadata[:activity_category]
    assert_equal "Durău", trail.metadata[:route_start]
    assert_equal "Vârful Toaca", trail.metadata[:route_end]
    assert_equal 210, trail.metadata[:duration_minutes]
    assert_equal 780, trail.metadata[:ascent_m]
    assert_equal 120, trail.metadata[:descent_m]
    assert_equal false, trail.metadata[:roundtrip]
    assert_equal "mountain_hiking", trail.metadata[:difficulty]
    assert_operator trail.metadata[:distance_km], :<, 20
    assert_in_delta 46.945, trail.metadata[:latitude], 0.001
    assert_in_delta 25.94, trail.metadata[:longitude], 0.001
    assert_equal "rwn", trail.metadata[:network]
    assert_equal "bandă roșie", trail.metadata[:route_ref]
    assert_equal "red:white:red_bar", trail.metadata[:trail_marker]
    assert_equal "Salvamont Neamț", trail.metadata[:route_operator]
    assert_equal "https://example.test/toaca", trail.metadata[:official_url]
    assert_includes trail.tags, "hiking"
    assert_match(/Verifică starea oficială/, trail.summary)
    assert_match(/punct panoramic/, items.find { |item| item.title == "Lumea Pierdută" }.summary)
    assert_match(/cabană alpină/, items.find { |item| item.title == "Cabana Dochia" }.summary)
    assert_not items.any? { |item| item.summary.match?(/viewpoint|alpine hut/) }

    queries = client.uris.map { |uri| URI.decode_www_form(uri.query).to_h.fetch("data") }
    assert queries.any? { |query| query.include?('["natural"="peak"]') }
    route_query = queries.find { |query| query.include?('["route"~"^(hiking|foot)$"]') }
    assert_match(/relation\([0-9.,-]+\)\["type"="route"\]/, route_query)
    assert_includes route_query, "out tags center 120"
  end


  test "normalizes common route distance and duration tag formats" do
    provider = Recommendations::Discovery::OverpassProvider.new(
      client: FakeClient.new, image_resolver: FakeImageResolver.new
    )

    assert_equal 8.5, provider.send(:route_distance, "8500 m")
    assert_equal 8.0, provider.send(:route_distance, "5 mi")
    assert_equal 8.5, provider.send(:route_distance, "8,5 km")
    assert_equal 210, provider.send(:duration_minutes, "3h 30min")
    assert_equal 150, provider.send(:duration_minutes, "2.5 hours")
    assert_equal 95, provider.send(:duration_minutes, "95 min")
    assert_equal 210, provider.send(:duration_minutes, "PT3H30M")
  end
end
