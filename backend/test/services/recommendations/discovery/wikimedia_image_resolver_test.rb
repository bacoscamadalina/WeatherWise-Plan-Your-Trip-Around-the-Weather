require "test_helper"

class Recommendations::Discovery::WikimediaImageResolverTest < ActiveSupport::TestCase
  class FakeClient
    attr_reader :uris

    def initialize
      @uris = []
    end

    def get_json(uri, headers: {})
      @uris << uri
      return wikidata_payload if uri.host == "www.wikidata.org"

      commons_payload
    end

    private

    def wikidata_payload
      {
        "entities" => {
          "Q123" => {
            "claims" => {
              "P18" => [
                { "mainsnak" => { "datavalue" => { "value" => "Museum facade.jpg" } } }
              ]
            }
          }
        }
      }
    end

    def commons_payload
      {
        "query" => {
          "pages" => [
            commons_page("Museum facade.jpg", "museum.jpg", "Museum Photographer"),
            commons_page("City park.jpg", "park.jpg", "Park Photographer")
          ]
        }
      }
    end

    def commons_page(filename, slug, artist)
      {
        "title" => "File:#{filename}",
        "imageinfo" => [
          {
            "thumburl" => "https://upload.wikimedia.org/#{slug}",
            "descriptionurl" => "https://commons.wikimedia.org/wiki/File:#{slug}",
            "extmetadata" => {
              "Artist" => { "value" => "<b>#{artist}</b>" },
              "LicenseShortName" => { "value" => "CC BY-SA 4.0" }
            }
          }
        ]
      }
    end
  end

  test "resolves direct Commons and Wikidata P18 images in batches with credits" do
    elements = [
      { "type" => "node", "id" => 1, "tags" => { "wikidata" => "Q123" } },
      { "type" => "way", "id" => 2, "tags" => { "wikimedia_commons" => "File:City park.jpg" } }
    ]
    client = FakeClient.new

    images = Recommendations::Discovery::WikimediaImageResolver.new(client:).resolve(elements, language: "ro")

    assert_equal "https://upload.wikimedia.org/museum.jpg", images.fetch("node/1").url
    assert_equal "Museum Photographer · CC BY-SA 4.0 · Wikimedia Commons", images.fetch("node/1").attribution
    assert_equal "https://upload.wikimedia.org/park.jpg", images.fetch("way/2").url
    assert_equal 2, client.uris.size

    commons_query = URI.decode_www_form(client.uris.last.query).to_h
    assert_equal "1200", commons_query.fetch("iiurlwidth")
    assert_equal "ro", commons_query.fetch("iiextmetadatalanguage")
    assert_includes commons_query.fetch("titles"), "File:Museum facade.jpg"
  end
end
