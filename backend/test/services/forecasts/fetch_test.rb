require "test_helper"

class Forecasts::FetchTest < ActiveSupport::TestCase
  class FakeProvider
    attr_reader :calls

    def initialize
      @calls = 0
    end

    def name = "fake"

    def daily_forecast(location:, days:)
      @calls += 1
      days.times.map do |index|
        {
          date: Date.current + index.days,
          weather_code: 0,
          temperature_min_c: 10,
          temperature_max_c: 20,
          precipitation_probability: 5,
          precipitation_mm: 0,
          wind_speed_kph: 8
        }
      end
    end
  end

  setup do
    @location = Location.create!(
      name: "Iași", country_code: "RO", latitude: 47.1585, longitude: 27.6014,
      timezone: "Europe/Bucharest", provider: "test", external_id: "iasi-fetch"
    )
    @provider = FakeProvider.new
    @service = Forecasts::Fetch.new(provider: @provider)
  end

  test "reuses fresh forecasts from the selected provider" do
    @service.call(location: @location, days: 2)
    second_result = @service.call(location: @location, days: 2)

    assert_equal 1, @provider.calls
    assert_equal %w[fake fake], second_result.map(&:provider)
  end

  test "refreshes stale forecasts" do
    @service.call(location: @location, days: 1)
    @location.daily_forecasts.where(provider: "fake").update_all(fetched_at: 2.hours.ago)

    @service.call(location: @location, days: 1)

    assert_equal 2, @provider.calls
  end
end
