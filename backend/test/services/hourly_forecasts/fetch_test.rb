require "test_helper"

class HourlyForecasts::FetchTest < ActiveSupport::TestCase
  class FakeProvider
    attr_reader :calls

    def initialize
      @calls = 0
    end

    def name = "fake_hourly"

    def hourly_forecast(location:, date:)
      @calls += 1
      24.times.map do |hour|
        {
          time: format("%sT%02d:00", date.iso8601, hour),
          weather_code: hour < 12 ? 61 : 1,
          temperature_c: 12,
          precipitation_probability: hour < 12 ? 70 : 10,
          precipitation_mm: hour < 12 ? 1 : 0,
          wind_speed_kph: 10,
          daylight: hour.between?(7, 19)
        }
      end
    end

    def hourly_forecast_range(location:, start_date:, end_date:)
      @calls += 1
      (start_date..end_date).flat_map { |date| hourly_payload(date) }
    end

    private

    def hourly_payload(date)
      24.times.map do |hour|
        {
          time: format("%sT%02d:00", date.iso8601, hour), weather_code: 1,
          temperature_c: 14, precipitation_probability: 10, precipitation_mm: 0,
          wind_speed_kph: 8, daylight: hour.between?(7, 19)
        }
      end
    end
  end

  setup do
    location = Location.create!(
      name: "Iași", country_code: "RO", latitude: 47.1585, longitude: 27.6014,
      timezone: "Europe/Bucharest", provider: "test", external_id: "iasi-hourly"
    )
    @daily = location.daily_forecasts.create!(
      forecast_date: Date.new(2026, 10, 2), provider: "fake_hourly",
      condition_code: "1", condition_label: "Mainly clear", weather_class: "clear",
      activity_context: "outdoor", temperature_min_c: 10, temperature_max_c: 20,
      precipitation_probability: 10, precipitation_mm: 0, wind_speed_kph: 8,
      fetched_at: Time.current
    )
    @provider = FakeProvider.new
    @service = HourlyForecasts::Fetch.new(provider: @provider)
  end

  test "persists and reuses a complete fresh local day" do
    first = @service.call(daily_forecast: @daily)
    second = @service.call(daily_forecast: @daily)

    assert_equal 24, first.size
    assert_equal 24, second.size
    assert_equal 1, @provider.calls
    assert_equal "rain", first.first.weather_class
  end

  test "refreshes a stale hourly day" do
    @service.call(daily_forecast: @daily)
    @daily.hourly_forecasts.update_all(fetched_at: 2.hours.ago)

    @service.call(daily_forecast: @daily)

    assert_equal 2, @provider.calls
  end

  test "fetches several days with one provider range request" do
    second = @daily.location.daily_forecasts.create!(
      forecast_date: @daily.forecast_date + 1.day, provider: "fake_hourly",
      condition_code: "1", condition_label: "Mainly clear", weather_class: "clear",
      activity_context: "outdoor", temperature_min_c: 10, temperature_max_c: 20,
      precipitation_probability: 10, precipitation_mm: 0, wind_speed_kph: 8,
      fetched_at: Time.current
    )

    result = @service.call_range(daily_forecasts: [ @daily, second ])

    assert_equal 1, @provider.calls
    assert_equal 24, result.fetch(@daily.forecast_date).size
    assert_equal 24, result.fetch(second.forecast_date).size
  end
end
