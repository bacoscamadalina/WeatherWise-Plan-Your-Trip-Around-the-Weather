require "test_helper"

class LocationImages::FetchTest < ActiveSupport::TestCase
  class CountingProvider < LocationImages::Provider
    attr_reader :calls

    def initialize(result)
      @result = result
      @calls = 0
    end

    def fetch(location:, language: "en")
      @calls += 1
      @result
    end
  end

  test "persists imagery and reuses it inside the cache window" do
    location = Locations::Search.new.call(query: "Iasi").first
    provider = CountingProvider.new(
      LocationImages::Result.new(
        image_url: "https://upload.wikimedia.org/iasi.jpg",
        attribution: "Photographer · CC BY-SA 4.0 · Wikimedia Commons",
        source_url: "https://commons.wikimedia.org/wiki/File:Iasi.jpg",
        provider: "wikimedia"
      )
    )
    fetcher = LocationImages::Fetch.new(provider:, ttl: 30.days)

    fetcher.call(location:, language: "ro")
    fetcher.call(location:, language: "ro")

    assert_equal 1, provider.calls
    assert_equal "https://upload.wikimedia.org/iasi.jpg", location.reload.hero_image_url
    assert_equal "wikimedia", location.hero_image_provider
    assert location.hero_image_fetched_at.present?
  end

  test "caches a safe miss instead of borrowing another locality" do
    location = Locations::Search.new.call(query: "Iasi").first
    provider = CountingProvider.new(nil)
    fetcher = LocationImages::Fetch.new(provider:, ttl: 30.days)

    fetcher.call(location:)
    fetcher.call(location:)

    assert_equal 1, provider.calls
    assert_nil location.reload.hero_image_url
    assert location.hero_image_fetched_at.present?
  end
end
