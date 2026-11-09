module Trips
  class DayNarrative
    ACTIVITY_SLOTS = %w[morning afternoon evening].freeze
    WET_CLASSES = %w[rain snow storm].freeze

    def initialize(trip_day:, forecast:, language: "en")
      @trip_day = trip_day
      @forecast = forecast
      @romanian = language.to_s.start_with?("ro")
    end

    def call
      "#{weather_overview} #{strategy}".strip
    end

    private

    def weather_overview
      label = localized_condition
      temperatures = "#{@forecast.temperature_min_c.to_i}–#{@forecast.temperature_max_c.to_i}°C"
      rain = @forecast.precipitation_probability.to_i
      @romanian ? "#{label}, #{temperatures}, #{rain}% ploaie." : "#{label}, #{temperatures}, #{rain}% rain."
    end

    def strategy
      items = @trip_day.itinerary_items.select { |item| ACTIVITY_SLOTS.include?(item.slot) }
      available = items.reject { |item| item.status == "unavailable" || item.kind == "free_time" }
      return no_stops if available.empty?

      wet = available.select { |item| wet_period?(item) }
      outdoor = available.select { |item| item.metadata["indoor"] == false && !wet_period?(item) }

      if wet.size == available.size
        return @romanian ?
          "Ploaia domină intervalele zilei, așa că planul prioritizează opriri la interior." :
          "Rain dominates the day’s time windows, so the plan prioritizes indoor stops."
      end
      if wet.any? && outdoor.any?
        return @romanian ?
          "Păstrăm opririle la interior #{slot_list(wet)}; folosim fereastra potrivită pentru exterior #{slot_list(outdoor)}." :
          "Stops in the #{slot_list(wet)} stay indoors; the #{slot_list(outdoor)} window is used for outdoors."
      end
      if outdoor.any?
        return @romanian ?
          "Condițiile permit activități în aer liber #{slot_list(outdoor)}." :
          "Conditions support outdoor activities in the #{slot_list(outdoor)}."
      end

      @romanian ?
        "Planul păstrează opriri flexibile, potrivite condițiilor din fiecare interval." :
        "The plan keeps flexible stops suited to each time window."
    end

    def wet_period?(item)
      weather = item.metadata["period_weather"] || {}
      weather["weather_class"].in?(WET_CLASSES) || weather["precipitation_probability"].to_i >= 50
    end

    def slot_list(items)
      labels = items.map(&:slot).uniq.map do |slot|
        if @romanian
          { "morning" => "dimineața", "afternoon" => "după-amiaza", "evening" => "seara" }.fetch(slot)
        else
          { "morning" => "morning", "afternoon" => "afternoon", "evening" => "evening" }.fetch(slot)
        end
      end
      connector = @romanian ? " și " : " and "
      labels.to_sentence(two_words_connector: connector, last_word_connector: connector)
    end

    def no_stops
      @romanian ?
        "Nu există încă suficiente opriri sigure; intervalele libere rămân marcate pentru completare." :
        "There are not enough safe stops yet; open periods remain marked for completion."
    end

    def localized_condition
      labels = if @romanian
        { "clear" => "Senin", "cloudy" => "Înnorat", "rain" => "Ploaie", "snow" => "Ninsoare", "storm" => "Furtună" }
      else
        { "clear" => "Clear", "cloudy" => "Cloudy", "rain" => "Rain", "snow" => "Snow", "storm" => "Storm" }
      end
      labels.fetch(@forecast.weather_class, @forecast.condition_label)
    end
  end
end
