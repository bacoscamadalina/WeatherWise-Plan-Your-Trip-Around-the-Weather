require "test_helper"

class Trips::PlannerTest < ActiveSupport::TestCase
  FakeSuggestion = Data.define(
    :recommendation, :score, :reason, :planning_notes, :distance_km,
    :recommended_periods, :availability
  )

  FakeDining = Struct.new(:venues) do
    def search(location:, meal:, radius_km:, language:, preferences: {})
      venues.fetch(meal)
    end
  end

  FakeRecommender = Struct.new(:suggestions) do
    def call(**)
      suggestions
    end
  end

  RecordingRecommender = Struct.new(:suggestions, :calls) do
    def call(**arguments)
      calls << arguments
      suggestions
    end
  end

  RecordingDining = Struct.new(:calls) do
    def search(**arguments)
      calls << arguments
      []
    end
  end

  FakeForecastFetcher = Struct.new(:calls) do
    def call(location:, days:, refresh: false)
      calls << { location:, days:, refresh: }
      location.daily_forecasts.order(:forecast_date).limit(days)
    end
  end

  FakeHourlyFetcher = Struct.new(:hours) do
    def call_range(daily_forecasts:, refresh: false)
      daily_forecasts.to_h { |forecast| [ forecast.forecast_date, hours ] }
    end
  end

  class FailingForecastFetcher
    def call(**)
      raise ExternalApi::Error, "weather offline"
    end
  end

  def setup
    @location = Location.create!(
      name: "Iași", country_code: "RO", latitude: 47.1585, longitude: 27.6014,
      timezone: "Europe/Bucharest", provider: "test", external_id: "planner-iasi"
    )
    @forecast = DailyForecast.create!(
      location: @location, forecast_date: Date.current, provider: "test",
      condition_code: "1", condition_label: "Mainly clear", weather_class: "clear",
      activity_context: "outdoor", temperature_min_c: 10, temperature_max_c: 22,
      precipitation_probability: 5, precipitation_mm: 0, wind_speed_kph: 8,
      fetched_at: Time.current
    )
    @trip = Trip.create!(
      location: @location, name: "O zi în Iași", starts_on: Date.current,
      ends_on: Date.current, max_distance_km: 50
    )
  end

  test "builds a weather-aware day with verified meals and no repeated activity" do
    activity_one = recommendation("Palatul Culturii", "planner-palace", indoor: true)
    activity_two = recommendation("Grădina Botanică", "planner-garden", indoor: false)
    suggestions = [ suggestion(activity_one, %w[morning afternoon]), suggestion(activity_two, %w[afternoon evening]) ]
    dining = FakeDining.new({
      "breakfast" => [ venue("breakfast", "Harmony Café") ],
      "lunch" => [ venue("lunch", "Zori Bistro") ],
      "dinner" => [ venue("dinner", "Veranda") ]
    })

    planned = Trips::Planner.new(
      recommender: FakeRecommender.new(suggestions), dining_provider: dining
    ).call(trip: @trip, language: "ro")

    day = planned.trip_days.first
    assert_equal 6, day.itinerary_items.size
    assert_equal %w[breakfast morning lunch afternoon dinner evening], day.itinerary_items.map(&:slot)
    assert_equal "Harmony Café", day.itinerary_items.first.title
    assert_equal 4.6, day.itinerary_items.first.rating.to_f
    assert_equal [ activity_one.id, activity_two.id ], day.itinerary_items.filter_map(&:recommendation_id)
    assert_equal "free_time", day.itinerary_items.last.kind
    assert_equal "planned", planned.status
  end

  test "explicitly refreshes weather before rebuilding an existing plan" do
    fetcher = FakeForecastFetcher.new([])
    dining = FakeDining.new({
      "breakfast" => [], "lunch" => [], "dinner" => []
    })

    planned = Trips::Planner.new(
      recommender: FakeRecommender.new([]),
      dining_provider: dining,
      forecast_fetcher: fetcher
    ).call(trip: @trip, language: "ro", refresh_weather: true)

    assert_equal true, fetcher.calls.first.fetch(:refresh)
    assert_equal @location, fetcher.calls.first.fetch(:location)
    assert_equal 1, fetcher.calls.first.fetch(:days)
    assert_equal 1, planned.trip_days.size
  end

  test "uses trip interests dietary preferences and budget while planning" do
    @location.daily_forecasts.create!(
      forecast_date: Date.current + 1.day, provider: "test", condition_code: "1",
      condition_label: "Mainly clear", weather_class: "clear", activity_context: "outdoor",
      temperature_min_c: 11, temperature_max_c: 23, precipitation_probability: 5,
      precipitation_mm: 0, wind_speed_kph: 9, fetched_at: Time.current
    )
    @trip.update!(preferences: {
      budget: "value", dietary: %w[vegetarian], interests: %w[nature]
    }, ends_on: Date.current + 1.day)
    recommendation_calls = []
    dining_calls = []

    Trips::Planner.new(
      recommender: RecordingRecommender.new([], recommendation_calls),
      dining_provider: RecordingDining.new(dining_calls)
    ).call(trip: @trip, language: "ro")

    assert_equal %w[nature], recommendation_calls.first.fetch(:activity_kinds)
    assert_equal 3, dining_calls.size, "meal discovery should be reused across all trip days"
    assert_equal "value", dining_calls.first.dig(:preferences, "budget")
    assert_equal %w[vegetarian], dining_calls.first.dig(:preferences, "dietary")
  end

  test "relaxed pace starts later and deliberately keeps the evening free" do
    @trip.update!(pace: "relaxed", transport_mode: "walking")
    activity_one = recommendation("Palatul Culturii", "relaxed-palace", indoor: true)
    activity_two = recommendation("Grădina Botanică", "relaxed-garden", indoor: false)
    suggestions = [ suggestion(activity_one, %w[morning]), suggestion(activity_two, %w[afternoon]) ]
    dining = FakeDining.new({ "breakfast" => [], "lunch" => [], "dinner" => [] })

    day = Trips::Planner.new(
      recommender: FakeRecommender.new(suggestions), dining_provider: dining
    ).call(trip: @trip, language: "ro").trip_days.first

    assert_equal "09:00", day.itinerary_items.first.starts_at.strftime("%H:%M")
    assert_equal "10:45", day.itinerary_items.find_by!(slot: "morning").starts_at.strftime("%H:%M")
    evening = day.itinerary_items.find_by!(slot: "evening")
    assert_equal "free_time", evening.kind
    assert_equal "Seară fără program", evening.title
    assert_equal "pace_rest", evening.metadata.fetch("reason")
    assert_equal 25, day.itinerary_items.find_by!(slot: "morning").metadata.fetch("travel_buffer_minutes")
  end

  test "active pace gives a known long activity enough time" do
    @trip.update!(pace: "active")
    trail = recommendation("Traseu montan", "active-trail", indoor: false)
    trail.update!(metadata: trail.metadata.merge(duration_minutes: 210))
    dining = FakeDining.new({ "breakfast" => [], "lunch" => [], "dinner" => [] })

    day = Trips::Planner.new(
      recommender: FakeRecommender.new([ suggestion(trail, %w[morning]) ]),
      dining_provider: dining,
      hourly_fetcher: FakeHourlyFetcher.new([])
    ).call(trip: @trip, language: "ro").trip_days.first
    item = day.itinerary_items.find_by!(slot: "morning")

    assert_equal "Traseu montan", item.title
    assert_equal "08:30", item.starts_at.strftime("%H:%M")
    assert_equal "12:00", item.ends_at.strftime("%H:%M")
    assert_equal 210, item.metadata.fetch("duration_minutes")
  end

  test "plans only periods after arrival and before departure" do
    @location.daily_forecasts.create!(
      forecast_date: Date.current + 1.day, provider: "test", condition_code: "1",
      condition_label: "Mainly clear", weather_class: "clear", activity_context: "outdoor",
      temperature_min_c: 11, temperature_max_c: 23, precipitation_probability: 5,
      precipitation_mm: 0, wind_speed_kph: 9, fetched_at: Time.current
    )
    @trip.update!(
      ends_on: Date.current + 1.day,
      arrival_time: "14:00",
      departure_time: "13:30"
    )
    dining = FakeDining.new({ "breakfast" => [], "lunch" => [], "dinner" => [] })

    days = Trips::Planner.new(
      recommender: FakeRecommender.new([]), dining_provider: dining,
      hourly_fetcher: FakeHourlyFetcher.new([])
    ).call(trip: @trip, language: "ro").trip_days

    assert_equal %w[afternoon dinner evening], days.first.itinerary_items.map(&:slot)
    assert_equal %w[breakfast morning], days.last.itinerary_items.map(&:slot)
  end

  test "does not place an exact-time event past the end of its period" do
    event = Recommendation.create!(
      location: @location, recommendation_type: "event", title: "Concert de prânz",
      summary: "Concert", indoor: true, provider: "test", external_id: "late-morning-event",
      weather_classes: %w[clear],
      metadata: { event_time: "11:30:00", duration_minutes: 120 }
    )
    dining = FakeDining.new({ "breakfast" => [], "lunch" => [], "dinner" => [] })

    day = Trips::Planner.new(
      recommender: FakeRecommender.new([ suggestion(event, %w[morning]) ]),
      dining_provider: dining
    ).call(trip: @trip, language: "ro").trip_days.first

    assert_equal "free_time", day.itinerary_items.find_by!(slot: "morning").kind
    refute day.itinerary_items.exists?(recommendation: event)
  end

  test "places outdoor activity in the dry hourly window and indoor activity in rain" do
    garden = recommendation("Grădina Botanică", "hourly-garden", indoor: false)
    museum = recommendation("Muzeul Unirii", "hourly-museum", indoor: true)
    hours = [
      hourly(10, weather_class: "rain", context: "indoor", rain: 80),
      hourly(11, weather_class: "rain", context: "indoor", rain: 75),
      hourly(15, weather_class: "clear", context: "outdoor", rain: 5),
      hourly(16, weather_class: "clear", context: "outdoor", rain: 5)
    ]
    dining = FakeDining.new({ "breakfast" => [], "lunch" => [], "dinner" => [] })

    day = Trips::Planner.new(
      recommender: FakeRecommender.new([
        suggestion(garden, %w[morning afternoon]),
        suggestion(museum, %w[morning afternoon])
      ]),
      dining_provider: dining,
      hourly_fetcher: FakeHourlyFetcher.new(hours)
    ).call(trip: @trip, language: "ro").trip_days.first

    morning = day.itinerary_items.find_by!(slot: "morning")
    afternoon = day.itinerary_items.find_by!(slot: "afternoon")
    assert_equal museum, morning.recommendation
    assert_equal "rain", morning.metadata.dig("period_weather", "weather_class")
    assert_equal garden, afternoon.recommendation
    assert_equal "clear", afternoon.metadata.dig("period_weather", "weather_class")
    assert_equal(
      "Între 10:00–12:30, riscul de ploaie ajunge la 80%; am ales o oprire la interior.",
      morning.summary
    )
    assert_equal "Potrivit pentru vreme", morning.metadata.fetch("ranking_reason")
    assert_equal(
      "Senin, 10–22°C, 5% ploaie. Păstrăm opririle la interior dimineața; " \
        "folosim fereastra potrivită pentru exterior după-amiaza.",
      day.summary
    )
  end

  test "prefers a similarly ranked activity near the previous stop" do
    far = recommendation("Far gallery", "far-gallery", indoor: true)
    near = recommendation("Nearby museum", "near-museum", indoor: true)
    far.update!(metadata: far.metadata.merge(latitude: 47.30, longitude: 27.80))
    near.update!(metadata: near.metadata.merge(latitude: 47.16, longitude: 27.60))
    dining = FakeDining.new({ "breakfast" => [], "lunch" => [], "dinner" => [] })

    day = Trips::Planner.new(
      recommender: FakeRecommender.new([
        suggestion(far, %w[morning]), suggestion(near, %w[morning])
      ]),
      dining_provider: dining
    ).call(trip: @trip, language: "ro").trip_days.first

    morning = day.itinerary_items.find_by!(slot: "morning")
    assert_equal near, morning.recommendation
    assert_operator morning.metadata.fetch("selection_distance_from_previous_km"), :<, 1
  end

  test "prefers a nearby equally rated restaurant for the current sequence" do
    far = venue("far-breakfast", "Far Café").with(latitude: 47.30, longitude: 27.80)
    near = venue("near-breakfast", "Near Café").with(latitude: 47.16, longitude: 27.60)
    dining = FakeDining.new({
      "breakfast" => [ far, near ], "lunch" => [], "dinner" => []
    })

    day = Trips::Planner.new(
      recommender: FakeRecommender.new([]), dining_provider: dining
    ).call(trip: @trip, language: "ro").trip_days.first

    breakfast = day.itinerary_items.find_by!(slot: "breakfast")
    assert_equal "Near Café", breakfast.title
    assert_operator breakfast.metadata.fetch("selection_distance_from_previous_km"), :<, 1
  end

  test "keeps persisted settings and itinerary when weather refresh fails" do
    dining = FakeDining.new({
      "breakfast" => [], "lunch" => [], "dinner" => []
    })
    planner = Trips::Planner.new(
      recommender: FakeRecommender.new([]), dining_provider: dining
    )
    planner.call(trip: @trip, language: "ro")
    original_day_id = @trip.reload.trip_days.first.id
    @trip.assign_attributes(max_distance_km: 20, pace: "relaxed")

    assert_raises(ExternalApi::Error) do
      Trips::Planner.new(
        recommender: FakeRecommender.new([]),
        dining_provider: dining,
        forecast_fetcher: FailingForecastFetcher.new
      ).call(trip: @trip, language: "ro", refresh_weather: true)
    end

    @trip.reload
    assert_equal 50.0, @trip.max_distance_km.to_f
    assert_equal "balanced", @trip.pace
    assert_equal original_day_id, @trip.trip_days.first.id
  end

  private

  def recommendation(title, external_id, indoor:)
    Recommendation.create!(
      location: @location, recommendation_type: "activity", title:,
      summary: title, indoor:, provider: "test", external_id:,
      weather_classes: %w[clear cloudy], metadata: { setting: indoor ? "indoor" : "outdoor" }
    )
  end

  def suggestion(recommendation, periods)
    FakeSuggestion.new(
      recommendation:, score: 80, reason: "Potrivit pentru vreme",
      planning_notes: [], distance_km: 2.5, recommended_periods: periods,
      availability: nil
    )
  end

  def venue(id, name)
    Dining::Venue.new(
      external_id: id, name:, address: "Iași", latitude: 47.16,
      longitude: 27.60, rating: 4.6, rating_count: 240, price_level: "MODERATE",
      types: %w[restaurant], url: "https://maps.google.com/?q=#{id}",
      provider: "google_places", distance_km: 1.2
    )
  end

  def hourly(hour, weather_class:, context:, rain:)
    HourlyForecast.new(
      daily_forecast: @forecast,
      forecast_at: Time.find_zone!(@location.timezone).local(Date.current.year, Date.current.month, Date.current.day, hour),
      provider: "test", condition_code: weather_class == "rain" ? "61" : "1",
      condition_label: weather_class.titleize, weather_class:,
      activity_context: context, temperature_c: 15,
      precipitation_probability: rain, precipitation_mm: weather_class == "rain" ? 1 : 0,
      wind_speed_kph: 10, daylight: true, fetched_at: Time.current
    )
  end
end
