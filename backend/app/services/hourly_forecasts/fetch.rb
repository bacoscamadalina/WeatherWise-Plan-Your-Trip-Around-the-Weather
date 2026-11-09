module HourlyForecasts
  class Fetch
    EXPECTED_HOURS = 24

    def initialize(provider: Weather::ProviderFactory.build, normalizer: Weather::HourlyNormalizer.new)
      @provider = provider
      @normalizer = normalizer
    end

    def call(daily_forecast:, refresh: false)
      stored = provider_scope(daily_forecast)
      refresh_from_provider(daily_forecast) if refresh || stored.size < EXPECTED_HOURS || stale?(stored)
      provider_scope(daily_forecast)
    end

    def call_range(daily_forecasts:, refresh: false)
      forecasts = Array(daily_forecasts).sort_by(&:forecast_date)
      return {} if forecasts.empty?

      if refresh || forecasts.any? { |forecast| incomplete_or_stale?(forecast) }
        refresh_range_from_provider(forecasts)
      end
      forecasts.to_h do |forecast|
        [ forecast.forecast_date, provider_scope(forecast).to_a ]
      end
    end

    private

    def refresh_from_provider(daily_forecast)
      location = daily_forecast.location
      provider_name = @provider.name

      HourlyForecast.transaction do
        @provider.hourly_forecast(location:, date: daily_forecast.forecast_date).each do |payload|
          attributes = @normalizer.call(payload, provider: provider_name, location:)
          hour = daily_forecast.hourly_forecasts.find_or_initialize_by(
            forecast_at: attributes.fetch(:forecast_at), provider: provider_name
          )
          hour.update!(attributes)
        end
      end
    end

    def refresh_range_from_provider(forecasts)
      location = forecasts.first.location
      by_date = forecasts.index_by(&:forecast_date)
      payloads = @provider.hourly_forecast_range(
        location:,
        start_date: forecasts.first.forecast_date,
        end_date: forecasts.last.forecast_date
      )

      HourlyForecast.transaction do
        payloads.each do |payload|
          attributes = @normalizer.call(payload, provider: @provider.name, location:)
          local_date = attributes.fetch(:forecast_at).in_time_zone(location.timezone).to_date
          daily = by_date[local_date]
          next unless daily

          hour = daily.hourly_forecasts.find_or_initialize_by(
            forecast_at: attributes.fetch(:forecast_at), provider: @provider.name
          )
          hour.update!(attributes)
        end
      end
    end

    def incomplete_or_stale?(daily_forecast)
      stored = provider_scope(daily_forecast)
      stored.size < EXPECTED_HOURS || stale?(stored)
    end

    def provider_scope(daily_forecast)
      daily_forecast.hourly_forecasts.where(provider: @provider.name).order(:forecast_at)
    end

    def stale?(forecasts)
      ttl = ENV.fetch(
        "HOURLY_FORECAST_CACHE_TTL_MINUTES",
        ENV.fetch("FORECAST_CACHE_TTL_MINUTES", 60)
      ).to_i.minutes
      oldest_fetch = forecasts.minimum(:fetched_at)
      oldest_fetch.nil? || oldest_fetch < ttl.ago
    end
  end
end
