module Trips
  class DayLogistics
    def initialize(trip_day:)
      @items = trip_day.itinerary_items.order(:position).to_a
    end

    def payload
      located = @items.select { |item| located?(item) }
      planned = @items.count { |item| item.status != "unavailable" && item.kind != "free_time" }
      return { planned_stops: planned, located_stops: 0, route_available: false } if located.empty?

      final_metadata = located.last.metadata
      durations = located.filter_map { |item| positive_integer(item.metadata["route_duration_minutes"]) }
      return_duration = positive_integer(final_metadata["return_route_duration_minutes"])
      distances = located.filter_map { |item| decimal(item.metadata["route_distance_km"]) }
      return_distance = decimal(final_metadata["return_route_distance_km"])
      expected_legs = located.size + 1
      all_distances = distances + [ return_distance ].compact
      route_statuses = located.map { |item| item.metadata["route_status"] }
      route_statuses << final_metadata["return_route_status"]

      {
        planned_stops: planned,
        located_stops: located.size,
        route_available: true,
        travel_minutes: durations.sum + return_duration.to_i,
        distance_km: all_distances.size == expected_legs ? all_distances.sum.round(1) : nil,
        estimated: route_statuses.any? { |status| status != "provider_route" },
        first_departure_at: located.first.metadata["route_departure_at"],
        return_arrival_at: final_metadata["return_route_arrival_at"],
        return_fits_day: final_metadata["return_route_fits_day"]
      }.compact
    end

    private

    def located?(item)
      item.latitude.present? && item.longitude.present? && item.status != "unavailable"
    end

    def positive_integer(value)
      number = value.to_i
      number if number.positive?
    end

    def decimal(value)
      number = value.to_f
      number if number.positive?
    end
  end
end
