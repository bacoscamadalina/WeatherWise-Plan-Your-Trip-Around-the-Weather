require "test_helper"

class Weather::ClassifierTest < ActiveSupport::TestCase
  test "classifies a pleasant clear day for outdoor activities" do
    result = Weather::Classifier.new.call(code: 0, temperature_max_c: 22, precipitation_probability: 5)

    assert_equal "clear", result.weather_class
    assert_equal "Clear", result.condition_label
    assert_equal "outdoor", result.activity_context
  end

  test "distinguishes mainly clear from overcast WMO conditions" do
    mainly_clear = Weather::Classifier.new.call(
      code: 1, temperature_max_c: 19, precipitation_probability: 0
    )
    overcast = Weather::Classifier.new.call(
      code: 3, temperature_max_c: 19, precipitation_probability: 0
    )

    assert_equal "clear", mainly_clear.weather_class
    assert_equal "Mainly clear", mainly_clear.condition_label
    assert_equal "cloudy", overcast.weather_class
    assert_equal "Overcast", overcast.condition_label
  end

  test "classifies rain for indoor activities" do
    result = Weather::Classifier.new.call(code: 61, temperature_max_c: 14, precipitation_probability: 80)

    assert_equal "rain", result.weather_class
    assert_equal "indoor", result.activity_context
  end

  test "classifies thunderstorms as caution" do
    result = Weather::Classifier.new.call(code: 95, temperature_max_c: 20, precipitation_probability: 70)

    assert_equal "storm", result.weather_class
    assert_equal "caution", result.activity_context
  end
end
