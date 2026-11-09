require "test_helper"

class Recommendations::RefreshingProviderTest < ActiveSupport::TestCase
  class FakeDiscoveryProvider < Recommendations::Discovery::Provider
    attr_reader :calls

    def initialize(location:, items: [], error: nil)
      @location = location
      @items = items
      @error = error
      @calls = 0
    end

    def name = "live-test"

    def cache_scope(request:)
      Recommendation.where(provider: name, location: @location)
    end

    def discover(request:)
      @calls += 1
      raise @error if @error

      @items
    end
  end

  setup do
    @location = Location.create!(
      name: "Iași", country_code: "RO", latitude: 47.1585, longitude: 27.6014,
      provider: "test", external_id: "iasi-refresh"
    )
    @request = Recommendations::Request.new(location: @location, forecast: nil, preferences: { type: "activity" })
  end

  test "persists discovered items and serves the cached result" do
    item = Recommendations::CatalogItem.new(
      location: @location, recommendation_type: "activity", title: "Nearby Museum",
      summary: "A local visit", venue_name: "Nearby Museum", indoor: true,
      provider: "live-test", external_id: "node/1", url: "https://example.test/node/1",
      genres: [], tags: %w[museum], weather_classes: %w[rain], metadata: { distance_km: 1.2 }
    )
    discovery = FakeDiscoveryProvider.new(location: @location, items: [ item ])
    provider = Recommendations::RefreshingProvider.new(
      activity_provider: discovery,
      movie_provider: Recommendations::Discovery::NullProvider.new
    )

    assert_equal [ "Nearby Museum" ], provider.suggestions(request: @request).map(&:title)
    assert_equal [ "Nearby Museum" ], provider.suggestions(request: @request).map(&:title)
    assert_equal 1, discovery.calls
  end

  test "keeps database fallbacks when live discovery fails" do
    Recommendation.create!(
      location: @location, recommendation_type: "activity", title: "Seeded Museum",
      summary: "Always available in the catalog", indoor: true, provider: "seed",
      external_id: "seeded", weather_classes: %w[rain]
    )
    discovery = FakeDiscoveryProvider.new(location: @location, error: ExternalApi::Error.new("offline"))
    provider = Recommendations::RefreshingProvider.new(
      activity_provider: discovery,
      movie_provider: Recommendations::Discovery::NullProvider.new
    )

    assert_equal [ "Seeded Museum" ], provider.suggestions(request: @request).map(&:title)
  end

  test "deactivates stale live items after a successful refresh" do
    stale = Recommendation.create!(
      location: @location, recommendation_type: "activity", title: "Old Result",
      summary: "No longer returned", indoor: false, provider: "live-test",
      external_id: "node/old", weather_classes: %w[clear], updated_at: 1.day.ago
    )
    replacement = Recommendations::CatalogItem.new(
      location: @location, recommendation_type: "activity", title: "Current Result",
      summary: "Still relevant", venue_name: "Current Result", indoor: true,
      provider: "live-test", external_id: "node/current", url: nil,
      genres: [], tags: %w[museum], weather_classes: %w[rain], metadata: {}
    )
    discovery = FakeDiscoveryProvider.new(location: @location, items: [ replacement ])
    provider = Recommendations::RefreshingProvider.new(
      activity_provider: discovery,
      movie_provider: Recommendations::Discovery::NullProvider.new
    )

    assert_equal [ "Current Result" ], provider.suggestions(request: @request).map(&:title)
    assert_not stale.reload.active
  end

  test "refreshes multiple event sources independently" do
    forecast = DailyForecast.new(forecast_date: Date.new(2026, 10, 6))
    request = Recommendations::Request.new(location: @location, forecast:, preferences: { type: "event" })
    ticketmaster = FakeDiscoveryProvider.new(location: @location)
    predicthq = FakeDiscoveryProvider.new(location: @location)

    provider = Recommendations::RefreshingProvider.new(
      activity_provider: Recommendations::Discovery::NullProvider.new,
      movie_provider: Recommendations::Discovery::NullProvider.new,
      event_providers: [ ticketmaster, predicthq ]
    )
    provider.suggestions(request:)

    assert_equal 1, ticketmaster.calls
    assert_equal 1, predicthq.calls
  end


  test "refreshes multiple activity sources independently" do
    wikipedia = FakeDiscoveryProvider.new(location: @location)
    overpass = FakeDiscoveryProvider.new(location: @location)
    provider = Recommendations::RefreshingProvider.new(
      activity_providers: [ wikipedia, overpass ],
      movie_provider: Recommendations::Discovery::NullProvider.new
    )

    provider.suggestions(request: @request)

    assert_equal 1, wikipedia.calls
    assert_equal 1, overpass.calls
  end

  test "serves the database cache instead of duplicating an in-flight refresh" do
    discovery = FakeDiscoveryProvider.new(location: @location)
    provider = Recommendations::RefreshingProvider.new(
      activity_provider: discovery,
      movie_provider: Recommendations::Discovery::NullProvider.new
    )
    lock = provider.send(:refresh_lock, discovery, @request)
    lock.lock

    assert_empty provider.suggestions(request: @request)
    assert_equal 0, discovery.calls
  ensure
    lock&.unlock if lock&.locked?
  end
end
