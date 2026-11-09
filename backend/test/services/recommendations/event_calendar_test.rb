require "test_helper"

class Recommendations::EventCalendarTest < ActiveSupport::TestCase
  class FakeRangeProvider
    attr_reader :calls

    def initialize(items)
      @items = items
      @calls = 0
    end

    def name = "range-test"

    def discover_range(location:, forecasts:, language:)
      @calls += 1
      @items
    end
  end

  test "returns only forecast days with real events and caches their listings" do
    location = Location.create!(
      name: "Paris", country_code: "FR", latitude: 48.8566, longitude: 2.3522,
      timezone: "Europe/Paris", provider: "test", external_id: "paris-calendar"
    )
    forecasts = [
      forecast(location, Date.new(2026, 10, 7)),
      forecast(location, Date.new(2026, 10, 8))
    ]
    item = Recommendations::CatalogItem.new(
      location:, recommendation_type: "event", title: "Paris Jazz Evening",
      summary: "A live concert", venue_name: "Test Hall", indoor: true,
      provider: "range-test", external_id: "paris:event-1", url: "https://example.test/event-1",
      genres: [ "jazz" ], tags: [ "event" ], weather_classes: %w[clear rain],
      metadata: { event_date: "2026-10-08", event_time: "19:30:00", image_url: "https://example.test/event.jpg" }
    )
    provider = FakeRangeProvider.new([ item ])

    days = Recommendations::EventCalendar.new(providers: [ provider ]).call(
      location:, forecasts:, language: "en"
    )

    assert_equal 1, provider.calls
    assert_equal [ Date.new(2026, 10, 8) ], days.map(&:date)
    assert_equal "Paris Jazz Evening", days.first.preview_title
    assert_equal "https://example.test/event.jpg", days.first.preview_image_url
    assert Recommendation.exists?(provider: "range-test", external_id: "paris:event-1")
  end

  private

  def forecast(location, date)
    DailyForecast.create!(
      location:, forecast_date: date, provider: "test", condition_code: "clear",
      condition_label: "Clear", weather_class: "clear", activity_context: "outdoor",
      temperature_min_c: 10, temperature_max_c: 20, precipitation_probability: 5,
      wind_speed_kph: 8, fetched_at: Time.current
    )
  end
end
