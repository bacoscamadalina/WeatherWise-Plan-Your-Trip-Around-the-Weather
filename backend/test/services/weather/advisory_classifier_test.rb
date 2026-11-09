require "test_helper"

class Weather::AdvisoryClassifierTest < ActiveSupport::TestCase
  test "returns no advisory for ordinary conditions" do
    assert_empty classifier.call(forecast)
  end

  test "prioritizes high-severity storm and wind advisories" do
    result = classifier.call(
      forecast(
        weather_class: "storm",
        precipitation_probability: 95,
        precipitation_mm: 20,
        wind_speed_kph: 65
      )
    )

    assert_equal 2, result.size
    assert_equal %w[storm heavy_rain], result.map(&:code)
    assert result.all? { |advisory| advisory.severity == "high" }
  end

  test "describes significant rain without calling it an official warning" do
    result = classifier.call(
      forecast(
        weather_class: "rain",
        precipitation_probability: 80,
        precipitation_mm: 7.2
      )
    ).sole

    assert_equal "rain", result.code
    assert_equal "moderate", result.severity
    assert_equal "A wet part of the day", result.title
  end

  test "adds heat and cold advisories at severe thresholds" do
    hot = classifier.call(forecast(temperature_max_c: 36)).sole
    cold = classifier.call(forecast(temperature_min_c: -12)).sole

    assert_equal "high_heat", hot.code
    assert_equal "severe_cold", cold.code
  end

  test "adds planning guidance for very high and extreme UV" do
    very_high = classifier.call(forecast(uv_index_max: 8.4)).sole
    extreme = classifier.call(forecast(uv_index_max: 11.2)).sole

    assert_equal "very_high_uv", very_high.code
    assert_equal "moderate", very_high.severity
    assert_equal "extreme_uv", extreme.code
    assert_equal "high", extreme.severity
  end

  private

  def classifier
    @classifier ||= Weather::AdvisoryClassifier.new
  end

  def forecast(overrides = {})
    DailyForecast.new(
      {
        weather_class: "clear",
        precipitation_probability: 10,
        precipitation_mm: 0,
        wind_speed_kph: 8,
        temperature_min_c: 10,
        temperature_max_c: 22
      }.merge(overrides)
    )
  end
end
