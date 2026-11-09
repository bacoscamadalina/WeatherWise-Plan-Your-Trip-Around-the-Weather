module Recommendations
  EventDay = Data.define(:date, :count, :preview_title, :preview_venue, :preview_image_url, :providers)

  class EventCalendar
    def initialize(providers: Discovery::ProviderFactory.events, deduplicator: EventDeduplicator.new)
      @providers = providers
      @deduplicator = deduplicator
    end

    def call(location:, forecasts:, language: "en")
      items = @providers.flat_map do |provider|
        next [] unless provider.respond_to?(:discover_range)

        provider.discover_range(location:, forecasts:, language:).tap do |discovered|
          discovered.each { |item| persist(item) }
        end
      rescue ExternalApi::Error => error
        Rails.logger.warn("#{provider.name} calendar discovery unavailable: #{error.message}")
        []
      end

      grouped = @deduplicator.call(items).group_by { |item| metadata(item, "event_date") }
      forecasts.filter_map do |forecast|
        day_items = grouped[forecast.forecast_date.iso8601]
        next if day_items.blank?

        preview = day_items.max_by { |item| preview_score(item) }
        EventDay.new(
          date: forecast.forecast_date,
          count: day_items.size,
          preview_title: preview.title,
          preview_venue: preview.venue_name,
          preview_image_url: metadata(preview, "image_url"),
          providers: day_items.map(&:provider).uniq.sort
        )
      end
    end

    private

    def persist(item)
      recommendation = Recommendation.find_or_initialize_by(provider: item.provider, external_id: item.external_id)
      recommendation.update!(item.to_h.except(:provider, :external_id).merge(active: true))
    end

    def metadata(item, key)
      item.metadata[key] || item.metadata[key.to_sym]
    end

    def preview_score(item)
      (item.url.present? ? 2 : 0) + (metadata(item, "image_url").present? ? 2 : 0) + (item.venue_name.present? ? 1 : 0)
    end
  end
end
