require "test_helper"

class Weather::HourlyNormalizerTest < ActiveSupport::TestCase
  test "normalizes a local provider timestamp into a persisted instant" do
    location = Struct.new(:timezone).new("Europe/Bucharest")
    attributes = Weather::HourlyNormalizer.new.call(
      {
        time: "2026-10-02T15:00",
        weather_code: 1,
        temperature_c: 20.5,
        precipitation_probability: 10,
        precipitation_mm: 0,
        wind_speed_kph: 8,
        daylight: true
      },
      provider: "test",
      location:
    )

    assert_equal Time.utc(2026, 10, 2, 12), attributes[:forecast_at]
    assert_equal "clear", attributes[:weather_class]
    assert_equal "outdoor", attributes[:activity_context]
    assert attributes[:daylight]
  end
end
