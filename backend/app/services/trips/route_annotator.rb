module Trips
  class RouteAnnotator
    LEG_KEYS = %w[
      route_origin_name route_status route_duration_minutes route_distance_km
      route_provider route_transport_mode route_caution_required route_fits_schedule
      route_departure_at route_arrival_at route_adjusted_minutes route_original_start
      route_before_day_start
    ].freeze
    RETURN_KEYS = %w[
      return_destination_name return_route_status return_route_duration_minutes
      return_route_distance_km return_route_provider return_route_departure_at
      return_route_arrival_at return_route_fits_day return_after_day_end_minutes
      return_arrives_next_day
    ].freeze

    def initialize(provider: Routing::ProviderFactory.build)
      @provider = provider
    end

    def reset!
      @provider_failed = false
      self
    end

    def call(trip_day:, trip:, language: "en")
      all_items = trip_day.itinerary_items.order(:position).to_a
      restore_rhythm_times(all_items)
      clear_stale_returns(all_items)
      items = all_items.select { |item| located?(item) }
      return trip_day if items.empty?

      origin = point(trip.location, trip.location.display_name)
      items.each do |item|
        destination = point(item, item.venue_name.presence || item.title)
        next_start = all_items.find { |candidate| candidate.position > item.position && candidate.starts_at }&.starts_at
        annotate_leg(item, origin, destination, trip, language, next_start)
        item.reload
        origin = destination.merge(ends_at: item.ends_at)
      end
      annotate_return(items.last, origin, point(trip.location, trip.location.display_name), trip, language)
      trip_day
    end

    private

    def annotate_leg(item, origin, destination, trip, language, next_start)
      route = route_between(
        origin,
        destination,
        trip,
        departure_clock: origin[:ends_at],
        arrival_clock: origin[:ends_at] ? nil : item.starts_at,
        date: item.trip_day.date,
        language:
      )
      metadata = item.metadata.except(*LEG_KEYS).merge(base_metadata(origin, trip))
      if route
        timing = route_timing(origin[:ends_at], item.starts_at, route, trip, item.trip_day.date)
        metadata.merge!(route_metadata(route)).merge!(timing)
        adjust_schedule(item, route, timing, next_start, trip, metadata, item.trip_day.date)
      end
      item.update!(metadata:)
    end

    def annotate_return(item, origin, destination, trip, language)
      route = route_between(
        origin,
        destination,
        trip,
        departure_clock: item.ends_at,
        arrival_clock: nil,
        date: item.trip_day.date,
        language:
      )
      duration = route&.duration_minutes || DailyRhythm.travel_buffer_minutes(trip.transport_mode)
      timing = return_timing(item.ends_at, duration, trip, item.trip_day.date)
      metadata = item.metadata.except(*RETURN_KEYS).merge(
        "return_destination_name" => destination.fetch(:name),
        "return_route_status" => route ? "provider_route" : "estimated_buffer",
        "return_route_duration_minutes" => duration,
        "return_route_distance_km" => route&.distance_km,
        "return_route_provider" => route&.provider,
        **timing
      ).compact
      item.update!(metadata:)
    end

    def route_between(origin, destination, trip, departure_clock:, arrival_clock:, date:, language:)
      return if @provider_failed

      @provider.route(
        origin: origin.slice(:latitude, :longitude),
        destination: destination.slice(:latitude, :longitude),
        transport_mode: trip.transport_mode,
        departure_at: route_time(date, departure_clock, trip.location.timezone),
        arrival_at: route_time(date, arrival_clock, trip.location.timezone),
        language:
      )
    rescue ExternalApi::Error, ArgumentError => error
      @provider_failed = true
      Rails.logger.warn("Route calculation unavailable: #{error.message}")
      nil
    end

    def base_metadata(origin, trip)
      {
        "route_origin_name" => origin.fetch(:name),
        "route_status" => "estimated_buffer",
        "route_duration_minutes" => DailyRhythm.travel_buffer_minutes(trip.transport_mode),
        "route_transport_mode" => trip.transport_mode,
        "route_caution_required" => trip.transport_mode.in?(%w[walking bicycle])
      }
    end

    def route_metadata(route)
      {
        "route_status" => "provider_route",
        "route_duration_minutes" => route.duration_minutes,
        "route_distance_km" => route.distance_km,
        "route_provider" => route.provider,
        "route_transport_mode" => route.transport_mode
      }
    end

    def route_timing(previous_end, current_start, route, trip, date)
      departure = previous_end || shift_time(current_start, -route.duration_minutes)
      arrival = shift_time(departure, route.duration_minutes)
      before_day_start = previous_end.nil? && departure < day_start(trip, date)
      {
        "route_departure_at" => departure.strftime("%H:%M"),
        "route_arrival_at" => arrival.strftime("%H:%M"),
        "route_fits_schedule" => arrival <= current_start,
        "route_before_day_start" => before_day_start
      }
    end

    def return_timing(departure, duration, trip, date)
      return {} unless departure

      arrival = shift_time(departure, duration)
      finish = day_end(trip, date)
      overrun = [ ((arrival - finish) / 60).ceil, 0 ].max
      {
        "return_route_departure_at" => departure.strftime("%H:%M"),
        "return_route_arrival_at" => arrival.strftime("%H:%M"),
        "return_route_fits_day" => overrun.zero?,
        "return_after_day_end_minutes" => overrun.positive? ? overrun : nil,
        "return_arrives_next_day" => arrival.to_date > finish.to_date
      }.compact
    end

    def adjust_schedule(item, route, timing, next_start, trip, metadata, date)
      return if timing.fetch("route_fits_schedule")
      return unless item.kind == "activity" && item.starts_at && item.ends_at

      delay = route.duration_minutes - gap_minutes(item.starts_at, timing.fetch("route_departure_at"))
      return unless delay.positive?

      original_start = item.starts_at
      shifted_start = shift_time(original_start, delay)
      duration = item.metadata["duration_minutes"].to_i
      shifted_end = duration.positive? ? shift_time(item.ends_at, delay) : item.ends_at
      boundary = [ next_start, day_end(trip, date) ].compact.min
      return unless shifted_start < shifted_end && shifted_end <= boundary

      item.update!(starts_at: shifted_start, ends_at: shifted_end)
      metadata.merge!(
        "route_fits_schedule" => true,
        "route_arrival_at" => shifted_start.strftime("%H:%M"),
        "route_adjusted_minutes" => delay,
        "route_original_start" => original_start.strftime("%H:%M")
      )
    end

    def route_time(date, clock_time, timezone)
      return unless clock_time

      zone = ActiveSupport::TimeZone[timezone] || Time.zone
      zone.local(date.year, date.month, date.day, clock_time.hour, clock_time.min)
    end

    def clear_stale_returns(items)
      items.each do |item|
        metadata = item.metadata.except(*RETURN_KEYS)
        item.update!(metadata:) if metadata != item.metadata
      end
    end

    def restore_rhythm_times(items)
      items.each do |item|
        metadata = item.metadata
        baseline_start = metadata["rhythm_starts_at"]
        baseline_end = metadata["rhythm_ends_at"]
        unless baseline_start || baseline_end
          item.update!(metadata: metadata.merge(
            "rhythm_starts_at" => item.starts_at&.strftime("%H:%M"),
            "rhythm_ends_at" => item.ends_at&.strftime("%H:%M")
          ).compact)
          next
        end

        item.update!(starts_at: baseline_start, ends_at: baseline_end)
      end
    end

    def located?(item) = item.latitude.present? && item.longitude.present? && item.status != "unavailable"

    def point(record, name)
      {
        name:,
        latitude: record.latitude.to_f,
        longitude: record.longitude.to_f
      }
    end

    def shift_time(value, delta)
      Time.utc(2000, 1, 1, value.hour, value.min) + delta.minutes
    end

    def gap_minutes(current_start, departure_label)
      departure_hours, departure_minutes = departure_label.split(":").map(&:to_i)
      minutes(current_start) - ((departure_hours * 60) + departure_minutes)
    end

    def day_end(trip, date)
      label = DailyRhythm.available_window(trip, date).fetch(:ends_at)
      hours, minutes = label.split(":").map(&:to_i)
      Time.utc(2000, 1, 1, hours, minutes)
    end

    def day_start(trip, date)
      label = DailyRhythm.available_window(trip, date).fetch(:starts_at)
      hours, minutes = label.split(":").map(&:to_i)
      Time.utc(2000, 1, 1, hours, minutes)
    end

    def minutes(value) = (value.hour * 60) + value.min
  end
end
