require "test_helper"

class Recommendations::Discovery::WikipediaPlacesProviderTest < ActiveSupport::TestCase
  class FakeClient
    attr_reader :uri

    def get_json(uri, headers: {})
      @uri = uri
      {
        "query" => {
          "pages" => [
            {
              "pageid" => 1,
              "title" => "Iași",
              "coordinates" => [ { "lat" => 47.1585, "lon" => 27.6014 } ],
              "pageimage" => "Iasi.jpg"
            },
            {
              "pageid" => 2,
              "title" => "Palace of Culture",
              "fullurl" => "https://en.wikipedia.org/wiki/Palace_of_Culture_(Ia%C8%99i)",
              "coordinates" => [ { "lat" => 47.1575, "lon" => 27.5869 } ],
              "pageimage" => "Palace.jpg"
            },
            {
              "pageid" => 3,
              "title" => "Iași metropolitan area",
              "fullurl" => "https://en.wikipedia.org/wiki/Ia%C8%99i_metropolitan_area",
              "coordinates" => [ { "lat" => 47.16, "lon" => 27.59 } ],
              "pageimage" => "Iasi metropolitan area map.svg"
            }
          ]
        }
      }
    end
  end

  class FakeImageResolver
    attr_reader :elements, :language

    def resolve(elements, language: "en")
      @elements = elements
      @language = language
      {
        "page/2" => Recommendations::Discovery::WikimediaImageResolver::Image.new(
          url: "https://upload.wikimedia.org/palace.jpg",
          attribution: "Photographer · CC BY-SA 4.0 · Wikimedia Commons",
          source_url: "https://commons.wikimedia.org/wiki/File:Palace.jpg"
        )
      }
    end
  end

  test "uses the requested Wikipedia language and localizes the generated summary" do
    client = FakeClient.new
    resolver = FakeImageResolver.new
    location = Location.new(name: "Iași", latitude: 47.1585, longitude: 27.6014)
    request = Recommendations::Request.new(
      location:,
      forecast: nil,
      preferences: { language: "ro" }
    )

    item = Recommendations::Discovery::WikipediaPlacesProvider.new(
      client:,
      image_resolver: resolver
    ).discover(request:).first

    assert_equal "ro.wikipedia.org", client.uri.host
    assert_match(/Un obiectiv remarcabil/, item.summary)
    assert_equal "ro", item.metadata[:language]
    assert_equal "ro", item.metadata[:content_language]
    assert_equal "ro", resolver.language
  end

  test "returns pictured nearby places and excludes the locality article itself" do
    client = FakeClient.new
    resolver = FakeImageResolver.new
    location = Location.new(name: "Iași", latitude: 47.1585, longitude: 27.6014)
    request = Recommendations::Request.new(location:, forecast: nil, preferences: {})

    items = Recommendations::Discovery::WikipediaPlacesProvider.new(
      client:,
      radius_meters: 5_000,
      image_resolver: resolver
    ).discover(request:)

    assert_equal [ "Palace of Culture" ], items.map(&:title)
    assert_equal "wikipedia", items.first.provider
    assert_equal "https://upload.wikimedia.org/palace.jpg", items.first.metadata[:image_url]
    assert_includes items.first.tags, "setting-unverified"
    assert_includes items.first.tags, "culture"
    assert_includes items.first.tags, "heritage"
    assert_equal "culture", items.first.metadata[:activity_kind]
    assert_equal "heritage", items.first.metadata[:activity_category]
    assert items.first.indoor
    assert_equal [ "page/2" ], resolver.elements.map { |element| "#{element.fetch("type")}/#{element.fetch("id")}" }

    query = URI.decode_www_form(client.uri.query).to_h
    assert_equal "5000", query.fetch("ggsradius")
    assert_equal "free", query.fetch("pilicense")
  end
end
