require "test_helper"

class Trips::DayNarrativeTest < ActiveSupport::TestCase
  setup do
    location = Location.create!(
      name: "Iași", country_code: "RO", latitude: 47.1585, longitude: 27.6014,
      timezone: "Europe/Bucharest", provider: "test", external_id: "narrative-iasi"
    )
    @forecast = location.daily_forecasts.create!(
      forecast_date: Date.new(2026, 10, 12), provider: "test",
      condition_code: "61", condition_label: "Rain", weather_class: "rain",
      activity_context: "indoor", temperature_min_c: 8, temperature_max_c: 14,
      precipitation_probability: 75, precipitation_mm: 4, wind_speed_kph: 16,
      fetched_at: Time.current
    )
    trip = Trip.create!(
      location:, name: "Weekend în Iași", starts_on: @forecast.forecast_date,
      ends_on: @forecast.forecast_date
    )
    @day = trip.trip_days.create!(
      date: @forecast.forecast_date, daily_forecast: @forecast,
      weather_class: "rain", activity_context: "indoor"
    )
  end

  test "describes an indoor strategy when every planned discovery has wet weather" do
    add_item("morning", "Muzeu", weather_class: "rain", rain: 80)
    add_item("afternoon", "Galerie", weather_class: "rain", rain: 65)

    narrative = Trips::DayNarrative.new(trip_day: @day, forecast: @forecast, language: "ro").call

    assert_equal(
      "Ploaie, 8–14°C, 75% ploaie. Ploaia domină intervalele zilei, " \
        "așa că planul prioritizează opriri la interior.",
      narrative
    )
  end

  test "does not count open time as a planned stop" do
    @day.itinerary_items.create!(
      slot: "evening", kind: "free_time", title: "Seară liberă", position: 1,
      starts_at: "19:00", ends_at: "22:00", metadata: {}
    )

    narrative = Trips::DayNarrative.new(trip_day: @day, forecast: @forecast, language: "en").call

    assert_includes narrative, "There are not enough safe stops yet"
  end

  test "localizes the connector between two outdoor periods" do
    add_item("morning", "Grădină", weather_class: "clear", rain: 5, indoor: false)
    add_item("afternoon", "Promenadă", weather_class: "clear", rain: 10, indoor: false)

    narrative = Trips::DayNarrative.new(trip_day: @day, forecast: @forecast, language: "ro").call

    assert_includes narrative, "în aer liber dimineața și după-amiaza"
    refute_includes narrative, " and "
  end

  private

  def add_item(slot, title, weather_class:, rain:, indoor: true)
    @day.itinerary_items.create!(
      slot:, kind: "activity", title:, position: @day.itinerary_items.size,
      starts_at: "10:00", ends_at: "12:00",
      metadata: {
        indoor:,
        period_weather: {
          source: "hourly", weather_class:,
          precipitation_probability: rain
        }
      }
    )
  end
end
