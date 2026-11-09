require "test_helper"

class LocationImages::WikimediaProviderTest < ActiveSupport::TestCase
  class FakeClient
    attr_reader :uris

    def initialize(article_payload:, metadata_payload:)
      @article_payload = article_payload
      @metadata_payload = metadata_payload
      @uris = []
    end

    def get_json(uri)
      @uris << uri
      uri.host == "commons.wikimedia.org" ? @metadata_payload : @article_payload
    end
  end

  class ExactTitleClient
    attr_reader :uris

    def initialize
      @uris = []
    end

    def get_json(uri)
      @uris << uri
      return metadata_payload if uri.host == "commons.wikimedia.org"
      return { "query" => { "pages" => [] } } if URI.decode_www_form(uri.query).to_h.key?("generator")

      {
        "query" => {
          "pages" => [
            {
              "ns" => 0,
              "title" => "Paris",
              "fullurl" => "https://en.wikipedia.org/wiki/Paris",
              "pageimage" => "Paris_montage.jpg",
              "thumbnail" => { "source" => "https://upload.wikimedia.org/paris-1600.jpg" }
            }
          ]
        }
      }
    end

    private

    def metadata_payload
      {
        "query" => {
          "pages" => [
            {
              "imageinfo" => [
                {
                  "descriptionurl" => "https://commons.wikimedia.org/wiki/File:Paris_montage.jpg",
                  "extmetadata" => {
                    "Artist" => { "value" => "Example" },
                    "LicenseShortName" => { "value" => "CC BY 4.0" }
                  }
                }
              ]
            }
          ]
        }
      }
    end
  end

  test "returns a freely licensed image only for the requested locality" do
    client = FakeClient.new(
      article_payload: {
        "query" => {
          "pages" => [
            {
              "pageid" => 1,
              "ns" => 0,
              "title" => "Iași",
              "fullurl" => "https://en.wikipedia.org/wiki/Ia%C8%99i",
              "pageimage" => "Palace_of_Culture_Iasi.jpg",
              "thumbnail" => { "source" => "https://upload.wikimedia.org/iasi-1600.jpg" }
            },
            {
              "pageid" => 2,
              "ns" => 0,
              "title" => "Palace of Culture",
              "pageimage" => "Other.jpg",
              "thumbnail" => { "source" => "https://upload.wikimedia.org/other.jpg" }
            }
          ]
        }
      },
      metadata_payload: {
        "query" => {
          "pages" => [
            {
              "imageinfo" => [
                {
                  "descriptionurl" => "https://commons.wikimedia.org/wiki/File:Palace_of_Culture_Iasi.jpg",
                  "extmetadata" => {
                    "Artist" => { "value" => "<a>Example Photographer</a>" },
                    "LicenseShortName" => { "value" => "CC BY-SA 4.0" }
                  }
                }
              ]
            }
          ]
        }
      }
    )
    location = Location.new(name: "Iași", latitude: 47.1585, longitude: 27.6014)

    result = LocationImages::WikimediaProvider.new(client:).fetch(location:, language: "ro-RO")

    assert_equal "https://upload.wikimedia.org/iasi-1600.jpg", result.image_url
    assert_equal "Example Photographer · CC BY-SA 4.0 · Wikimedia Commons", result.attribution
    assert_equal "wikimedia", result.provider
    assert_equal "https://commons.wikimedia.org/wiki/File:Palace_of_Culture_Iasi.jpg", result.source_url

    article_query = URI.decode_www_form(client.uris.first.query).to_h
    assert_equal "free", article_query.fetch("pilicense")
    assert_equal "47.1585|27.6014", article_query.fetch("ggscoord")
    metadata_query = URI.decode_www_form(client.uris.last.query).to_h
    assert_equal "ro", metadata_query.fetch("iiextmetadatalanguage")
  end

  test "rejects a nearby landmark when no page identifies the locality" do
    client = FakeClient.new(
      article_payload: {
        "query" => {
          "pages" => [
            {
              "ns" => 0,
              "title" => "Unrelated nearby castle",
              "pageimage" => "Castle.jpg",
              "thumbnail" => { "source" => "https://upload.wikimedia.org/castle.jpg" }
            }
          ]
        }
      },
      metadata_payload: {}
    )
    location = Location.new(name: "Small Village", latitude: 47.0, longitude: 27.0)

    assert_nil LocationImages::WikimediaProvider.new(client:).fetch(location:)
    assert_equal 2, client.uris.size
  end

  test "falls back to exact locality titles when the locality article is not geotagged at its center" do
    client = ExactTitleClient.new
    location = Location.new(
      name: "Paris",
      admin_area: "Île-de-France",
      country_name: "France",
      latitude: 48.85341,
      longitude: 2.3488
    )

    result = LocationImages::WikimediaProvider.new(client:).fetch(location:)

    assert_equal "https://upload.wikimedia.org/paris-1600.jpg", result.image_url
    title_query = URI.decode_www_form(client.uris.second.query).to_h
    assert_includes title_query.fetch("titles"), "Paris, France"
    assert_equal "free", title_query.fetch("pilicense")
  end
end
