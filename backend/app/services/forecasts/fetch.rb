module Forecasts
  class Fetch
    MAX_DAYS = 14

    def initialize(provider: Weather::ProviderFactory.build, normalizer: Weather::Normalizer.new)
      @provider = provider
      @normalizer = normalizer
    end

    def call(location:, days: MAX_DAYS, refresh: false)
      days = days.to_i.clamp(1, MAX_DAYS)
      range = Date.current...(Date.current + days.days)
      stored = provider_scope(location, range)

      refresh_from_provider(location, days) if refresh || stored.size < days || stale?(stored)
      provider_scope(location, range).limit(days)
    end

    private

    def refresh_from_provider(location, days)
      provider_name = @provider.name
      @provider.daily_forecast(location:, days:).each do |payload|
        attributes = @normalizer.call(payload, provider: provider_name)
        forecast = location.daily_forecasts.find_or_initialize_by(
          forecast_date: attributes.fetch(:forecast_date), provider: provider_name
        )
        forecast.update!(attributes)
      end
    end

    def provider_scope(location, range)
      location.daily_forecasts
        .where(provider: @provider.name, forecast_date: range)
        .order(:forecast_date)
    end

    def stale?(forecasts)
      ttl = ENV.fetch("FORECAST_CACHE_TTL_MINUTES", 60).to_i.minutes
      oldest_fetch = forecasts.minimum(:fetched_at)
      oldest_fetch.nil? || oldest_fetch < ttl.ago
    end
  end
end
