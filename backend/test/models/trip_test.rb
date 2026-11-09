require "test_helper"

class TripTest < ActiveSupport::TestCase
  def setup
    @location = Location.create!(
      name: "Iași", country_code: "RO", latitude: 47.1585, longitude: 27.6014,
      timezone: "Europe/Bucharest", provider: "test", external_id: "trip-model-iasi"
    )
  end

  test "accepts a fourteen day trip with a radius up to fifty kilometres" do
    trip = Trip.new(
      location: @location, name: "Iași in the sun", starts_on: Date.current,
      ends_on: Date.current + 13.days, max_distance_km: 50
    )

    assert_predicate trip, :valid?
    assert_equal 14, trip.day_count
  end

  test "rejects a trip outside the forecast horizon" do
    trip = Trip.new(
      location: @location, name: "Too long", starts_on: Date.current,
      ends_on: Date.current + 14.days
    )

    assert_not trip.valid?
    assert_includes trip.errors[:ends_on], "must be within 14 days of the start date"
  end

  test "normalizes and validates planning preferences" do
    trip = Trip.new(
      location: @location, name: "Personalized", starts_on: Date.current,
      ends_on: Date.current, preferences: {
        budget: "moderate", dietary: %w[vegan vegan], interests: %w[nature culture]
      }
    )

    assert_predicate trip, :valid?
    assert_equal "moderate", trip.preferences.fetch("budget")
    assert_equal %w[vegan], trip.preferences.fetch("dietary")
    assert_equal %w[nature culture], trip.preferences.fetch("interests")

    trip.preferences = { budget: "luxury", dietary: %w[unknown], interests: %w[sports] }
    assert_not trip.valid?
    assert_equal 3, trip.errors[:preferences].size
  end

  test "requires departure after arrival for a one-day trip" do
    trip = Trip.new(
      location: @location, name: "Short visit", starts_on: Date.current,
      ends_on: Date.current, arrival_time: "18:00", departure_time: "11:00"
    )

    assert_not trip.valid?
    assert_includes trip.errors[:departure_time],
      "must be after the arrival time for a one-day trip"

    trip.departure_time = "21:00"
    assert_predicate trip, :valid?
  end
end
