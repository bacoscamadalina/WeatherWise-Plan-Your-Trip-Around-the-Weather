module Trips
  class DailyRhythm
    PROFILES = {
      "relaxed" => {
        label: { en: "Relaxed", ro: "Relaxat" },
        description: {
          en: "A later start, two main discoveries and generous pauses.",
          ro: "Start mai târziu, două descoperiri principale și pauze generoase."
        },
        periods: [
          { slot: "breakfast", kind: "meal", starts_at: "09:00", ends_at: "10:00" },
          { slot: "morning", kind: "activity", starts_at: "10:45", ends_at: "12:45" },
          { slot: "lunch", kind: "meal", starts_at: "13:15", ends_at: "14:30" },
          { slot: "afternoon", kind: "activity", starts_at: "15:30", ends_at: "18:00" },
          { slot: "dinner", kind: "meal", starts_at: "19:00", ends_at: "20:30" },
          { slot: "evening", kind: "rest", starts_at: "20:30", ends_at: "22:00" }
        ]
      },
      "balanced" => {
        label: { en: "Balanced", ro: "Echilibrat" },
        description: {
          en: "Three discoveries with breathing room between meals and travel.",
          ro: "Trei descoperiri, cu timp suficient între mese și deplasări."
        },
        periods: [
          { slot: "breakfast", kind: "meal", starts_at: "08:30", ends_at: "09:30" },
          { slot: "morning", kind: "activity", starts_at: "10:00", ends_at: "12:30" },
          { slot: "lunch", kind: "meal", starts_at: "13:00", ends_at: "14:00" },
          { slot: "afternoon", kind: "activity", starts_at: "14:30", ends_at: "18:00" },
          { slot: "dinner", kind: "meal", starts_at: "19:00", ends_at: "20:30" },
          { slot: "evening", kind: "activity", starts_at: "20:30", ends_at: "22:30" }
        ]
      },
      "active" => {
        label: { en: "Active", ro: "Activ" },
        description: {
          en: "An early start, longer exploration windows and a full evening.",
          ro: "Start devreme, intervale lungi de explorare și o seară completă."
        },
        periods: [
          { slot: "breakfast", kind: "meal", starts_at: "07:30", ends_at: "08:15" },
          { slot: "morning", kind: "activity", starts_at: "08:30", ends_at: "12:00" },
          { slot: "lunch", kind: "meal", starts_at: "12:15", ends_at: "13:15" },
          { slot: "afternoon", kind: "activity", starts_at: "13:45", ends_at: "18:00" },
          { slot: "dinner", kind: "meal", starts_at: "18:30", ends_at: "19:30" },
          { slot: "evening", kind: "activity", starts_at: "20:00", ends_at: "22:30" }
        ]
      }
    }.freeze

    TRAVEL_BUFFER_MINUTES = {
      "walking" => 25,
      "public_transport" => 30,
      "car" => 20,
      "bicycle" => 20
    }.freeze

    class << self
      def periods(pace)
        profile(pace).fetch(:periods).map(&:dup)
      end

      def periods_for(trip, date)
        window = available_window(trip, date)
        periods(trip.pace).select do |period|
          to_minutes(period.fetch(:starts_at)) >= to_minutes(window.fetch(:starts_at)) &&
            to_minutes(period.fetch(:ends_at)) <= to_minutes(window.fetch(:ends_at))
        end
      end

      def available_window(trip, date)
        selected = profile(trip.pace).fetch(:periods)
        starts_at = selected.first.fetch(:starts_at)
        ends_at = selected.last.fetch(:ends_at)
        if date == trip.starts_on && trip.arrival_time
          starts_at = later_clock(starts_at, trip.arrival_time.strftime("%H:%M"))
        end
        if date == trip.ends_on && trip.departure_time
          ends_at = earlier_clock(ends_at, trip.departure_time.strftime("%H:%M"))
        end
        { starts_at:, ends_at: }
      end

      def payload(pace:, transport_mode:, language: "en")
        selected = profile(pace)
        periods = selected.fetch(:periods)
        locale = language.to_s.start_with?("ro") ? :ro : :en
        {
          pace: pace,
          label: selected.fetch(:label).fetch(locale),
          description: selected.fetch(:description).fetch(locale),
          day_start: periods.first.fetch(:starts_at),
          day_end: periods.last.fetch(:ends_at),
          planned_activity_count: periods.count { |period| period.fetch(:kind) == "activity" },
          travel_buffer_minutes: TRAVEL_BUFFER_MINUTES.fetch(transport_mode, 20)
        }
      end

      def travel_buffer_minutes(transport_mode)
        TRAVEL_BUFFER_MINUTES.fetch(transport_mode, 20)
      end

      private

      def profile(pace)
        PROFILES.fetch(pace.to_s, PROFILES.fetch("balanced"))
      end

      def later_clock(first, second)
        to_minutes(first) >= to_minutes(second) ? first : second
      end

      def earlier_clock(first, second)
        to_minutes(first) <= to_minutes(second) ? first : second
      end

      def to_minutes(value)
        hours, minutes = value.split(":").map(&:to_i)
        (hours * 60) + minutes
      end
    end
  end
end
