require "test_helper"

class Recommendations::Discovery::TmdbProviderTest < ActiveSupport::TestCase
  class FakeClient
    attr_reader :uri, :headers, :uris

    def get_json(uri, headers: {})
      @uri = uri
      @headers = headers
      @uris ||= []
      @uris << uri
      {
        "results" => [
          {
            "id" => 42, "title" => "A Rainy Mystery", "overview" => "A careful whodunit.",
            "genre_ids" => [ 9648, 35 ], "poster_path" => "/poster.jpg",
            "vote_average" => 8.1, "release_date" => "2026-09-10"
          }
        ]
      }
    end
  end

  test "uses server-side bearer authentication and maps provider-neutral movies" do
    client = FakeClient.new
    location = Location.new(country_code: "RO")
    request = Recommendations::Request.new(location:, forecast: nil, preferences: { language: "ro" })
    item = Recommendations::Discovery::TmdbProvider.new(client:, token: "test-token").discover(request:).first

    assert_equal "Bearer test-token", client.headers.fetch("Authorization")
    assert_equal "application/json", client.headers.fetch("Accept")
    assert_equal "A Rainy Mystery", item.title
    assert_equal %w[mystery comedy], item.genres
    assert_includes item.weather_classes, "rain"
    assert_equal "https://image.tmdb.org/t/p/w500/poster.jpg", item.metadata[:poster_url]
    assert_equal "ro", item.metadata[:language]
    assert_equal "ro-42", item.external_id
    assert_equal "RO", URI.decode_www_form(client.uri.query).to_h.fetch("region")
    assert_equal "ro-RO", URI.decode_www_form(client.uri.query).to_h.fetch("language")
    assert_equal %w[1 2 3], client.uris.map { |uri| URI.decode_www_form(uri.query).to_h.fetch("page") }
  end

  test "caches each interface language independently" do
    request = Recommendations::Request.new(
      location: Location.new(country_code: "RO"),
      forecast: nil,
      preferences: { language: "ro" }
    )
    scope = Recommendations::Discovery::TmdbProvider.new(client: FakeClient.new, token: "test-token")
      .cache_scope(request:)

    assert_match(/metadata/, scope.to_sql)
    assert_match(/language/, scope.to_sql)
  end

  test "requires a token" do
    request = Recommendations::Request.new(location: Location.new(country_code: "RO"), forecast: nil, preferences: {})

    assert_raises(ExternalApi::Error) do
      Recommendations::Discovery::TmdbProvider.new(client: FakeClient.new, token: nil).discover(request:)
    end
  end
end
