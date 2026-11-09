module Recommendations
  class EventDeduplicator
    def call(items)
      non_events, events = items.partition { |item| item.recommendation_type != "event" }
      non_events + events.group_by { |item| signature(item) }.values.map { |matches| best(matches) }
    end

    private

    def signature(item)
      title = I18n.transliterate(item.title.to_s).downcase.gsub(/[^a-z0-9]+/, " ").squish
      date = metadata_value(item, "event_date")
      time = metadata_value(item, "event_time").to_s.first(5)
      [ title, date, time ]
    end

    def best(items)
      items.max_by do |item|
        metadata = item.metadata
        score = 0
        score += 4 if item.url.present?
        score += 3 if (metadata["image_url"] || metadata[:image_url]).present?
        score += 2 if item.venue_name.present?
        score += 1 if (metadata["latitude"] || metadata[:latitude]).present? &&
          (metadata["longitude"] || metadata[:longitude]).present?
        score
      end
    end

    def metadata_value(item, key)
      item.metadata[key] || item.metadata[key.to_sym]
    end
  end
end
