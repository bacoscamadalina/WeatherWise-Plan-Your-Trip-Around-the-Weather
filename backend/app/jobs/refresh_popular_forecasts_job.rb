class RefreshPopularForecastsJob < ApplicationJob
  queue_as :weather

  DEFAULT_LOOKBACK_DAYS = 2
  DEFAULT_MIN_REQUESTS = 3
  ACCESS_RETENTION_DAYS = 30

  def perform(
    as_of: Date.current,
    lookback_days: configured_lookback_days,
    min_requests: configured_min_requests,
    days: Forecasts::Fetch::MAX_DAYS
  )
    popular_location_ids(
      as_of:,
      lookback_days: lookback_days.to_i.clamp(1, ACCESS_RETENTION_DAYS),
      min_requests: [ min_requests.to_i, 1 ].max
    ).each do |location_id|
      RefreshLocationForecastJob.perform_later(location_id, days: days.to_i.clamp(1, Forecasts::Fetch::MAX_DAYS))
    end

    ForecastAccess.where(accessed_on: ...(as_of - ACCESS_RETENTION_DAYS)).delete_all
  end

  private

  def popular_location_ids(as_of:, lookback_days:, min_requests:)
    start_date = as_of - (lookback_days - 1).days
    ForecastAccess
      .where(accessed_on: start_date..as_of)
      .group(:location_id)
      .having("SUM(request_count) >= ?", min_requests)
      .pluck(:location_id)
  end

  def configured_lookback_days
    ENV.fetch("POPULAR_FORECAST_LOOKBACK_DAYS", DEFAULT_LOOKBACK_DAYS)
  end

  def configured_min_requests
    ENV.fetch("POPULAR_FORECAST_MIN_REQUESTS", DEFAULT_MIN_REQUESTS)
  end
end
