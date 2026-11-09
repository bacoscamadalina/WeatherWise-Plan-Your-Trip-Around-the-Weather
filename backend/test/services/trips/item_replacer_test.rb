require "test_helper"

class Trips::ItemReplacerTest < ActiveSupport::TestCase
  FakeSuggestion = Data.define(
    :recommendation, :score, :reason, :planning_notes, :distance_km,
    :recommended_periods, :availability
  )

  FakeRecommender = Struct.new(:suggestions) do
    def call(**)
      suggestions
    end
  end

  FakeDining = Struct.new(:venues) do
    def search(**)
      venues
    end
  end

  class FailingDining
    def search(**)
      raise ExternalApi::Error, "places offline"
    end
  end

  def setup
    @location = Location.create!(
      name: "Iași", country_code: "RO", latitude: 47.1585, longitude: 27.6014,
      timezone: "Europe/Bucharest", provider: "test", external_id: "replace-iasi"
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
    @day = @trip.trip_days.create!(
      date: Date.current, daily_forecast: @forecast,
      weather_class: "clear", activity_context: "outdoor"
    )
  end

  test "replaces only the requested activity with an unused weather-safe suggestion" do
    current = recommendation("Palatul Culturii", "current", indoor: true)
    used = recommendation("Grădina Botanică", "used", indoor: false)
    alternative = recommendation("Muzeul Unirii", "alternative", indoor: true)
    item = itinerary_item(current, slot: "morning", position: 1)
    other = itinerary_item(used, slot: "afternoon", position: 3)
    suggestions = [ current, used, alternative ].map { |value| suggestion(value) }

    result = Trips::ItemReplacer.new(
      recommender: FakeRecommender.new(suggestions),
      dining_provider: FakeDining.new([])
    ).call(item:, language: "ro")

    item.reload
    assert_equal alternative.id, item.recommendation_id
    assert_equal "Muzeul Unirii", item.title
    assert_equal "morning", item.slot
    assert_equal 1, item.position
    assert_equal "10:00", item.starts_at.strftime("%H:%M")
    assert_equal "Grădina Botanică", other.reload.title
    assert_equal @trip.id, result.id
  end

  test "keeps the activity unchanged when no different suggestion exists" do
    current = recommendation("Palatul Culturii", "only", indoor: true)
    item = itinerary_item(current, slot: "morning", position: 1)

    assert_raises(Trips::NoAlternativeError) do
      Trips::ItemReplacer.new(
        recommender: FakeRecommender.new([ suggestion(current) ]),
        dining_provider: FakeDining.new([])
      ).call(item:, language: "ro")
    end

    assert_equal current.id, item.reload.recommendation_id
    assert_equal "Palatul Culturii", item.title
  end

  test "replaces a meal with a different verified venue" do
    item = @day.itinerary_items.create!(
      slot: "lunch", kind: "meal", title: "Bistro vechi", position: 2,
      starts_at: "13:00", provider: "google_places", external_id: "old"
    )
    @day.itinerary_items.create!(
      slot: "dinner", kind: "meal", title: "Deja ales", position: 4,
      provider: "google_places", external_id: "used"
    )

    Trips::ItemReplacer.new(
      recommender: FakeRecommender.new([]),
      dining_provider: FakeDining.new([
        venue("old", "Bistro vechi"),
        venue("used", "Deja ales"),
        venue("far", "Prea departe", distance_km: 75),
        venue("new", "Prânz nou")
      ])
    ).call(item:, language: "ro")

    item.reload
    assert_equal "Prânz nou", item.title
    assert_equal "new", item.external_id
    assert_equal 4.7, item.rating.to_f
    assert_equal 180, item.rating_count
    assert_equal true, item.metadata.fetch("verified_rating")
  end

  test "keeps a meal unchanged when its provider fails" do
    item = @day.itinerary_items.create!(
      slot: "dinner", kind: "meal", title: "Cină păstrată", position: 4,
      starts_at: "19:00", provider: "google_places", external_id: "kept"
    )

    assert_raises(ExternalApi::Error) do
      Trips::ItemReplacer.new(
        recommender: FakeRecommender.new([]),
        dining_provider: FailingDining.new
      ).call(item:, language: "ro")
    end

    assert_equal "Cină păstrată", item.reload.title
    assert_equal "kept", item.external_id
  end

  private

  def recommendation(title, external_id, indoor:)
    Recommendation.create!(
      location: @location, recommendation_type: "activity", title:,
      summary: title, indoor:, provider: "test", external_id:,
      weather_classes: %w[clear cloudy],
      metadata: { setting: indoor ? "indoor" : "outdoor" }
    )
  end

  def itinerary_item(recommendation, slot:, position:)
    @day.itinerary_items.create!(
      recommendation:, slot:, kind: "activity", title: recommendation.title,
      position:, starts_at: slot == "morning" ? "10:00" : "14:30",
      provider: recommendation.provider, external_id: recommendation.external_id
    )
  end

  def suggestion(recommendation)
    FakeSuggestion.new(
      recommendation:, score: 80, reason: "Potrivit pentru vreme",
      planning_notes: [], distance_km: 2.5,
      recommended_periods: %w[morning afternoon], availability: nil
    )
  end

  def venue(id, name, distance_km: 1.4)
    Dining::Venue.new(
      external_id: id, name:, address: "Iași", latitude: 47.16,
      longitude: 27.60, rating: 4.7, rating_count: 180,
      price_level: "MODERATE", types: %w[restaurant],
      url: "https://maps.google.com/?q=#{id}", provider: "google_places",
      distance_km:
    )
  end
end
