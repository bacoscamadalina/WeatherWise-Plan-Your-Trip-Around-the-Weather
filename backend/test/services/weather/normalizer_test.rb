require "test_helper"

class Weather::NormalizerTest < ActiveSupport::TestCase
  test "normalizes provider data into persistence attributes" do
    attributes = Weather::Normalizer.new.call(
      {
        date: "2026-10-02",
        weather_code: 61,
        temperature_min_c: 8.5,
        temperature_max_c: 14.2,
        precipitation_probability: 75,
        precipitation_mm: 5.3,
        wind_speed_kph: 12,
        uv_index_max: 4.8,
        sunrise_local: "2026-10-02T07:13",
        sunset_local: "2026-10-02T18:49",
        daylight_duration_seconds: 41_760
      },
      provider: "test"
    )

    assert_equal Date.new(2026, 10, 2), attributes[:forecast_date]
    assert_equal "rain", attributes[:weather_class]
    assert_equal "indoor", attributes[:activity_context]
    assert_equal "test", attributes[:provider]
    assert_equal 4.8, attributes[:uv_index_max]
    assert_equal "2026-10-02T07:13", attributes[:sunrise_local]
    assert_equal 41_760, attributes[:daylight_duration_seconds]
  end
end
