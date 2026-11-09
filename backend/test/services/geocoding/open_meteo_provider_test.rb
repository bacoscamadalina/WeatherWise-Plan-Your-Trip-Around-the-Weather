require "test_helper"

class Geocoding::OpenMeteoProviderTest < ActiveSupport::TestCase
  class FakeClient
    attr_reader :uri

    def get_json(uri)
      @uri = uri
      {
        "results" => [
          {
            "id" => 675810,
            "name" => "Iaşi",
            "latitude" => 47.16667,
            "longitude" => 27.6,
            "country_code" => "RO",
            "country" => "România",
            "admin1" => "Iaşi",
            "timezone" => "Europe/Bucharest",
            "feature_code" => "PPLA",
            "population" => 271_692,
            "postcodes" => [ "700000" ]
          }
        ]
      }
    end
  end

  test "maps a global geocoding result to the provider-neutral contract" do
    client = FakeClient.new
    result = Geocoding::OpenMeteoProvider.new(client:, language: "ro").search(query: "Iași", limit: 3).first

    assert_equal "Iaşi", result.name
    assert_equal "RO", result.country_code
    assert_equal "open_meteo", result.provider
    assert_equal "675810", result.external_id
    assert_equal "România", result.country_name
    assert_equal "PPLA", result.feature_code
    assert_equal 271_692, result.population
    assert_equal [ "700000" ], result.aliases
    assert_equal "Iași", URI.decode_www_form(client.uri.query).to_h.fetch("name")
    assert_equal "ro", URI.decode_www_form(client.uri.query).to_h.fetch("language")
  end

  test "accepts per-request locale and up to one hundred ranked candidates" do
    client = FakeClient.new
    Geocoding::OpenMeteoProvider.new(client:, language: "en").search(
      query: "Paris",
      limit: 75,
      language: "fr"
    )

    query = URI.decode_www_form(client.uri.query).to_h
    assert_equal "75", query.fetch("count")
    assert_equal "fr", query.fetch("language")
  end
end
