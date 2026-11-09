module Recommendations
  class Timing
    PERIODS = %w[morning afternoon evening].freeze
    PERIOD_MINUTES = {
      "morning" => 10 * 60,
      "afternoon" => 14 * 60,
      "evening" => 19 * 60
    }.freeze
    DAY_CODES = %w[Su Mo Tu We Th Fr Sa].freeze
    SIMPLE_RULE = /\A(?<days>(?:Mo|Tu|We|Th|Fr|Sa|Su)(?:-(?:Mo|Tu|We|Th|Fr|Sa|Su))?(?:,(?:Mo|Tu|We|Th|Fr|Sa|Su)(?:-(?:Mo|Tu|We|Th|Fr|Sa|Su))?)*)\s+(?<times>off|\d{2}:\d{2}-\d{2}:\d{2}(?:,\d{2}:\d{2}-\d{2}:\d{2})*)\z/
    DISCLAIMER = "Provider-listed hours can change. Verify before visiting.".freeze

    def periods(item)
      return [ "evening" ] if item.recommendation_type == "movie"
      return periods_for_event(item) if item.recommendation_type == "event"

      tags = item.tags.map(&:downcase)
      return %w[afternoon evening] if (tags & %w[cinema theatre entertainment bowling escape_room]).any?
      return %w[morning afternoon] unless item.indoor?
      return %w[morning afternoon] if (tags & %w[museum gallery culture history art]).any?

      PERIODS
    end

    def availability(item:, date:, period:)
      return unless period && item.recommendation_type == "activity"

      raw_hours = item.metadata["opening_hours"].presence
      return availability_payload("not_listed", "Hours are not listed for this place", period) unless raw_hours

      status = listed_status(raw_hours, date, PERIOD_MINUTES.fetch(period))
      case status
      when :open
        availability_payload("listed_open", "Listed as open in the #{period}", period)
      when :closed
        availability_payload("listed_closed", "Listed as closed in the #{period}", period)
      else
        availability_payload("check_required", "Check the listed hours for the #{period}", period)
      end
    end

    private

    def periods_for_event(item)
      event_time = item.metadata["event_time"].presence
      return PERIODS unless event_time

      hour = event_time.split(":").first.to_i
      return [ "morning" ] if hour < 12
      return [ "afternoon" ] if hour < 17

      [ "evening" ]
    end

    def availability_payload(status, label, period)
      { status:, label:, period:, disclaimer: DISCLAIMER }
    end

    def listed_status(raw_hours, date, target_minute)
      return :open if raw_hours.strip == "24/7"

      rules = raw_hours.split(";").map(&:strip).reject(&:empty?).map { |rule| parse_rule(rule) }
      return :unknown if rules.empty? || rules.any?(&:nil?)

      day_code = DAY_CODES.fetch(date.wday)
      matching_rules = rules.select { |rule| rule[:days].include?(day_code) }
      return :closed if matching_rules.empty?
      return :closed if matching_rules.any? { |rule| rule[:off] }

      matching_rules.any? do |rule|
        rule[:ranges].any? { |range| minute_in_range?(target_minute, range) }
      end ? :open : :closed
    end

    def parse_rule(rule)
      match = SIMPLE_RULE.match(rule)
      return unless match

      ranges = match[:times] == "off" ? [] : match[:times].split(",").map { |range| parse_range(range) }
      return if ranges.any?(&:nil?)

      {
        days: expand_days(match[:days]),
        off: match[:times] == "off",
        ranges:
      }
    end

    def expand_days(expression)
      expression.split(",").flat_map do |part|
        start_code, end_code = part.split("-", 2)
        next [ start_code ] unless end_code

        start_index = DAY_CODES.index(start_code)
        end_index = DAY_CODES.index(end_code)
        end_index += DAY_CODES.length if end_index < start_index
        (start_index..end_index).map { |index| DAY_CODES[index % DAY_CODES.length] }
      end.uniq
    end

    def parse_range(range)
      values = range.split("-").map { |time| minutes(time) }
      return if values.any?(&:nil?)

      values
    end

    def minutes(time)
      hours, minutes = time.split(":").map(&:to_i)
      return if hours > 24 || minutes > 59 || (hours == 24 && minutes.positive?)

      (hours * 60) + minutes
    end

    def minute_in_range?(minute, range)
      start_minute, end_minute = range
      return minute >= start_minute && minute < end_minute if end_minute > start_minute

      minute >= start_minute || minute < end_minute
    end
  end
end
