require "test_helper"

class Trips::PeriodWeatherTest < ActiveSupport::TestCase
  setup do
    @location = Location.create!(
      name: "Iași", country_code: "RO", latitude: 47.1585, longitude: 27.6014,
      timezone: "Europe/Bucharest", provider: "test", external_id: "period-weather-iasi"
    )
    @forecast = @location.daily_forecasts.create!(
      forecast_date: Date.new(2026, 10, 12), provider: "test",
      condition_code: "1", condition_label: "Mainly clear", weather_class: "clear",
      activity_context: "outdoor", temperature_min_c: 10, temperature_max_c: 20,
      precipitation_probability: 10, precipitation_mm: 0, wind_speed_kph: 8,
      fetched_at: Time.current
    )
    @period = { starts_at: "10:00", ends_at: "12:30" }
  end

  test "summarizes the worst conditions inside the period" do
    create_hour(10, weather_class: "cloudy", rain: 35, temperature: 14)
    create_hour(11, weather_class: "rain", rain: 80, temperature: 12)
    create_hour(15, weather_class: "clear", rain: 5, temperature: 18)

    payload = period_weather.payload

    assert_equal "hourly", payload.fetch(:source)
    assert_equal "rain", payload.fetch(:weather_class)
    assert_equal 80, payload.fetch(:precipitation_probability)
    assert_equal 12.0, payload.fetch(:temperature_min_c)
    assert_equal 14.0, payload.fetch(:temperature_max_c)
  end

  test "rejects an outdoor stop in a rainy window but keeps an indoor stop" do
    create_hour(10, weather_class: "rain", rain: 75, temperature: 12)
    outdoor = recommendation("Promenadă", indoor: false)
    indoor = recommendation("Muzeu", indoor: true)

    refute period_weather.safe_for?(outdoor)
    assert period_weather.safe_for?(indoor)
    assert_operator period_weather.preference(indoor), :<, period_weather.preference(outdoor)
    assert_equal(
      "Între 10:00–12:30, riscul de ploaie ajunge la 75%; am ales o oprire la interior.",
      period_weather.reason_for(indoor, language: "ro")
    )
  end

  test "explains why an outdoor stop fits a dry hourly window" do
    create_hour(10, weather_class: "clear", rain: 5, temperature: 16)
    outdoor = recommendation("Grădină", indoor: false)

    assert_equal(
      "The 10:00–12:30 window is suitable for outdoors, with rain risk up to 5%.",
      period_weather.reason_for(outdoor, language: "en")
    )
  end

  private

  def period_weather
    Trips::PeriodWeather.new(hours: @forecast.hourly_forecasts, period: @period, forecast: @forecast)
  end

  def create_hour(hour, weather_class:, rain:, temperature:)
    @forecast.hourly_forecasts.create!(
      forecast_at: Time.find_zone!(@location.timezone).local(2026, 10, 12, hour),
      provider: "test", condition_code: weather_class == "rain" ? "61" : "3",
      condition_label: weather_class.titleize, weather_class:,
      activity_context: weather_class == "rain" ? "indoor" : "flexible",
      temperature_c: temperature, precipitation_probability: rain,
      precipitation_mm: weather_class == "rain" ? 1.2 : 0,
      wind_speed_kph: 10, daylight: true, fetched_at: Time.current
    )
  end

  def recommendation(title, indoor:)
    Recommendation.create!(
      location: @location, recommendation_type: "activity", title:,
      summary: title, indoor:, provider: "test", external_id: title.parameterize,
      weather_classes: %w[clear cloudy rain], metadata: { setting: indoor ? "indoor" : "outdoor" }
    )
  end
end
