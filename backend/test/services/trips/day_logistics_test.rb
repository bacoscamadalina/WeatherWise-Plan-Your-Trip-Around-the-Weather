require "test_helper"

class Trips::DayLogisticsTest < ActiveSupport::TestCase
  setup do
    location = Location.create!(
      name: "Iași", country_code: "RO", latitude: 47.1585, longitude: 27.6014,
      timezone: "Europe/Bucharest", provider: "test", external_id: "logistics-iasi"
    )
    trip = Trip.create!(
      location:, name: "Iași", starts_on: Date.current, ends_on: Date.current
    )
    @day = trip.trip_days.create!(date: Date.current)
  end

  test "summarizes calculated route time distance and return" do
    @day.itinerary_items.create!(
      slot: "morning", kind: "activity", title: "Museum", position: 0,
      latitude: 47.16, longitude: 27.60, starts_at: "10:00", ends_at: "12:00",
      metadata: {
        route_status: "provider_route", route_duration_minutes: 12,
        route_distance_km: 2.0, route_departure_at: "09:48"
      }
    )
    @day.itinerary_items.create!(
      slot: "afternoon", kind: "activity", title: "Garden", position: 1,
      latitude: 47.17, longitude: 27.57, starts_at: "14:30", ends_at: "17:00",
      metadata: {
        route_status: "provider_route", route_duration_minutes: 18,
        route_distance_km: 3.0, return_route_status: "provider_route",
        return_route_duration_minutes: 20, return_route_distance_km: 4.0,
        return_route_arrival_at: "17:20", return_route_fits_day: true
      }
    )

    payload = Trips::DayLogistics.new(trip_day: @day).payload

    assert_equal 2, payload.fetch(:planned_stops)
    assert_equal 2, payload.fetch(:located_stops)
    assert_equal 50, payload.fetch(:travel_minutes)
    assert_equal 9.0, payload.fetch(:distance_km)
    assert_equal false, payload.fetch(:estimated)
    assert_equal "09:48", payload.fetch(:first_departure_at)
    assert_equal "17:20", payload.fetch(:return_arrival_at)
  end

  test "labels mixed route evidence as estimated and omits incomplete distance" do
    @day.itinerary_items.create!(
      slot: "morning", kind: "activity", title: "Museum", position: 0,
      latitude: 47.16, longitude: 27.60,
      metadata: {
        route_status: "estimated_buffer", route_duration_minutes: 20,
        return_route_status: "estimated_buffer", return_route_duration_minutes: 20
      }
    )

    payload = Trips::DayLogistics.new(trip_day: @day).payload

    assert_equal true, payload.fetch(:estimated)
    assert_equal 40, payload.fetch(:travel_minutes)
    assert_nil payload[:distance_km]
  end
end
