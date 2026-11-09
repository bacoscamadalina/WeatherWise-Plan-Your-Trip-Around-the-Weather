require "test_helper"

class Showtimes::MovieGluProviderTest < ActiveSupport::TestCase
  class FakeClient
    attr_reader :calls

    def initialize
      @calls = []
    end

    def get_json(uri, headers: {})
      @calls << { uri:, headers: }
      return { "films" => [ { "film_id" => 7, "film_name" => "Rain Story", "film_image" => "https://example.test/film.jpg" } ] } if uri.path.include?("filmsNowShowing")
      return { "url" => "https://cinema.example.test/book" } if uri.path.include?("purchaseConfirmation")

      {
        "cinemas" => [
          {
            "cinema_id" => 9,
            "cinema_name" => "Central Cinema",
            "distance" => 2.0,
            "showings" => {
              "Standard" => { "times" => [ { "start_time" => "19:30", "end_time" => "21:40" } ] }
            }
          }
        ]
      }
    end
  end

  class FakeClock
    def self.current = Time.utc(2026, 10, 1, 12)
  end

  test "fetches uncached showtimes with server-side credentials" do
    client = FakeClient.new
    provider = Showtimes::MovieGluProvider.new(
      client:,
      endpoint: "https://example.test/",
      credentials: {
        client: "weatherwise", api_key: "key", authorization: "Basic token",
        territory: "RO", api_version: "v200"
      },
      clock: FakeClock
    )
    request = Showtimes::Request.new(
      location: Location.new(latitude: 47.1585, longitude: 27.6014),
      date: Date.new(2026, 10, 2),
      limit: 5
    )

    listing = provider.for_date(request:).first

    assert_equal 2, client.calls.size
    assert_equal "47.1585;27.6014", client.calls.first[:headers].fetch("geolocation")
    assert_equal "key", client.calls.first[:headers].fetch("x-api-key")
    assert_equal "2026-10-02", URI.decode_www_form(client.calls.last[:uri].query).to_h.fetch("date")
    assert_equal "Rain Story", listing.film_title
    assert_equal "Central Cinema", listing.cinema_name
    assert_equal 3.2, listing.distance_km
    assert_equal "19:30", listing.start_time
  end

  test "requires every credential" do
    provider = Showtimes::MovieGluProvider.new(
      client: FakeClient.new,
      credentials: { client: nil, api_key: nil, authorization: nil, territory: nil, api_version: "v200" }
    )
    request = Showtimes::Request.new(location: Location.new, date: Date.current, limit: 1)

    assert_raises(ExternalApi::Error) { provider.for_date(request:) }
  end

  test "resolves a provider booking handoff only when requested" do
    client = FakeClient.new
    provider = Showtimes::MovieGluProvider.new(
      client:,
      endpoint: "https://example.test/",
      credentials: {
        client: "weatherwise", api_key: "key", authorization: "Basic token",
        territory: "RO", api_version: "v200"
      },
      clock: FakeClock
    )
    request = Showtimes::BookingRequest.new(
      location: Location.new(latitude: 47.1585, longitude: 27.6014),
      date: Date.new(2026, 10, 2),
      film_id: "7",
      cinema_id: "9",
      time: "19:30"
    )

    assert_equal "https://cinema.example.test/book", provider.booking_link(request:)
    query = URI.decode_www_form(client.calls.first[:uri].query).to_h
    assert_equal "9", query.fetch("cinema_id")
    assert_equal "19:30", query.fetch("time")
  end
end
