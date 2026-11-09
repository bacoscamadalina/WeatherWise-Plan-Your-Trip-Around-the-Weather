require "test_helper"

class Trips::RouteAnnotatorTest < ActiveSupport::TestCase
  RecordingProvider = Struct.new(:routes, :calls) do
    def route(**arguments)
      calls << arguments
      routes.shift
    end
  end

  def setup
    @location = Location.create!(
      name: "Iași", country_code: "RO", latitude: 47.1585, longitude: 27.6014,
      timezone: "Europe/Bucharest", provider: "test", external_id: "route-iasi"
    )
    @trip = Trip.create!(
      location: @location, name: "Iași în mișcare", starts_on: Date.current,
      ends_on: Date.current, transport_mode: "car"
    )
    @day = @trip.trip_days.create!(date: Date.current)
    @first = @day.itinerary_items.create!(
      slot: "breakfast", kind: "meal", title: "Cafenea", venue_name: "Cafenea",
      latitude: 47.16, longitude: 27.60, starts_at: "08:30", ends_at: "09:30", position: 0
    )
    @second = @day.itinerary_items.create!(
      slot: "morning", kind: "activity", title: "Grădina Botanică",
      latitude: 47.1747, longitude: 27.5719, starts_at: "10:00", ends_at: "12:00", position: 1
    )
  end

  test "annotates sequential live legs and the return to the base location" do
    provider = RecordingProvider.new([
      route(8, 2.1), route(14, 4.2), route(17, 5.3)
    ], [])

    Trips::RouteAnnotator.new(provider:).call(trip_day: @day, trip: @trip, language: "ro")

    assert_equal "Iași, RO", @first.reload.metadata.fetch("route_origin_name")
    assert_equal "provider_route", @first.metadata.fetch("route_status")
    assert_equal 8, @first.metadata.fetch("route_duration_minutes")
    assert_equal "08:22", @first.metadata.fetch("route_departure_at")
    assert_equal "Cafenea", @second.reload.metadata.fetch("route_origin_name")
    assert_equal 4.2, @second.metadata.fetch("route_distance_km")
    assert_equal true, @second.metadata.fetch("route_fits_schedule")
    assert_equal "Iași, RO", @second.metadata.fetch("return_destination_name")
    assert_equal 17, @second.metadata.fetch("return_route_duration_minutes")
    assert_equal "12:17", @second.metadata.fetch("return_route_arrival_at")
    assert_equal true, @second.metadata.fetch("return_route_fits_day")
    assert_equal @first.latitude.to_f, provider.calls.second.dig(:origin, :latitude)
    assert_nil provider.calls.first[:departure_at]
    assert provider.calls.first[:arrival_at]
    assert provider.calls.second[:departure_at]
    assert_nil provider.calls.second[:arrival_at]
  end

  test "labels rhythm buffers honestly when no live provider is configured" do
    provider = RecordingProvider.new([ nil, nil, nil ], [])

    Trips::RouteAnnotator.new(provider:).call(trip_day: @day, trip: @trip)

    assert_equal "estimated_buffer", @first.reload.metadata.fetch("route_status")
    assert_equal 20, @first.metadata.fetch("route_duration_minutes")
    assert_nil @first.metadata["route_distance_km"]
    assert_equal "estimated_buffer", @second.reload.metadata.fetch("return_route_status")
    assert_equal "12:20", @second.metadata.fetch("return_route_arrival_at")
    assert_equal true, @second.metadata.fetch("return_route_fits_day")
  end

  test "flags a return that ends after the selected daily rhythm" do
    @second.update!(starts_at: "20:30", ends_at: "22:20")
    provider = RecordingProvider.new([
      route(8, 2.1), route(14, 4.2), route(35, 18.0)
    ], [])

    Trips::RouteAnnotator.new(provider:).call(trip_day: @day, trip: @trip, language: "ro")

    @second.reload
    assert_equal "22:20", @second.metadata.fetch("return_route_departure_at")
    assert_equal "22:55", @second.metadata.fetch("return_route_arrival_at")
    assert_equal false, @second.metadata.fetch("return_route_fits_day")
    assert_equal 25, @second.metadata.fetch("return_after_day_end_minutes")
  end

  test "keeps an after-midnight return later than the same-day rhythm boundary" do
    @second.update!(starts_at: "20:30", ends_at: "22:20")
    provider = RecordingProvider.new([
      route(8, 2.1), route(14, 4.2), route(120, 90.0)
    ], [])

    Trips::RouteAnnotator.new(provider:).call(trip_day: @day, trip: @trip)

    @second.reload
    assert_equal "00:20", @second.metadata.fetch("return_route_arrival_at")
    assert_equal true, @second.metadata.fetch("return_arrives_next_day")
    assert_equal false, @second.metadata.fetch("return_route_fits_day")
    assert_equal 110, @second.metadata.fetch("return_after_day_end_minutes")
  end

  test "uses the departure time as the final-day return boundary" do
    @trip.update!(departure_time: "11:00")
    @first.destroy!
    @second.update!(starts_at: "09:00", ends_at: "10:30")
    provider = RecordingProvider.new([ route(10, 2.0), route(45, 16.0) ], [])

    Trips::RouteAnnotator.new(provider:).call(trip_day: @day, trip: @trip)

    @second.reload
    assert_equal "11:15", @second.metadata.fetch("return_route_arrival_at")
    assert_equal false, @second.metadata.fetch("return_route_fits_day")
    assert_equal 15, @second.metadata.fetch("return_after_day_end_minutes")
  end

  test "moves a flexible activity later when a calculated route exceeds the gap" do
    @first.update!(ends_at: "09:55")
    provider = RecordingProvider.new([
      route(8, 2.1), route(20, 4.2), route(17, 5.3)
    ], [])

    Trips::RouteAnnotator.new(provider:).call(trip_day: @day, trip: @trip)

    @second.reload
    assert_equal "10:15", @second.starts_at.strftime("%H:%M")
    assert_equal "12:00", @second.ends_at.strftime("%H:%M")
    assert_equal true, @second.metadata.fetch("route_fits_schedule")
    assert_equal 15, @second.metadata.fetch("route_adjusted_minutes")
    assert_equal "10:00", @second.metadata.fetch("route_original_start")

    shorter_provider = RecordingProvider.new([
      route(8, 2.1), route(5, 1.4), route(17, 5.3)
    ], [])
    Trips::RouteAnnotator.new(provider: shorter_provider).call(
      trip_day: @day, trip: @trip
    )

    assert_equal "10:00", @second.reload.starts_at.strftime("%H:%M")
    assert_nil @second.metadata["route_adjusted_minutes"]
  end

  test "clears a stale return before a later replacement becomes the final located stop" do
    first_pass = RecordingProvider.new([ route(8, 2.1), route(14, 4.2), route(17, 5.3) ], [])
    annotator = Trips::RouteAnnotator.new(provider: first_pass)
    annotator.call(trip_day: @day, trip: @trip)
    assert @second.reload.metadata.key?("return_destination_name")

    dinner = @day.itinerary_items.create!(
      slot: "dinner", kind: "meal", title: "Cină", latitude: 47.18,
      longitude: 27.58, starts_at: "19:00", ends_at: "20:30", position: 4
    )
    second_pass = RecordingProvider.new([
      route(8, 2.1), route(14, 4.2), route(25, 8.0), route(12, 3.0)
    ], [])

    Trips::RouteAnnotator.new(provider: second_pass).call(trip_day: @day, trip: @trip)

    refute @second.reload.metadata.key?("return_destination_name")
    assert_equal "Iași, RO", dinner.reload.metadata.fetch("return_destination_name")
  end

  test "stops calling a failed provider for the rest of the plan" do
    provider = Class.new do
      attr_reader :calls

      def initialize = @calls = 0

      def route(**)
        @calls += 1
        raise ExternalApi::Error, "routing offline"
      end
    end.new

    Trips::RouteAnnotator.new(provider:).call(trip_day: @day, trip: @trip)

    assert_equal 1, provider.calls
    assert_equal "estimated_buffer", @first.reload.metadata.fetch("route_status")
    assert_equal "estimated_buffer", @second.reload.metadata.fetch("route_status")
  end

  private

  def route(duration, distance)
    Routing::Route.new(
      duration_minutes: duration,
      distance_km: distance,
      provider: "test_routes",
      transport_mode: "car"
    )
  end
end
