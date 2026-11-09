class RefreshLocationForecastJob < ApplicationJob
  queue_as :weather

  discard_on ActiveRecord::RecordNotFound
  retry_on ExternalApi::Error, wait: :polynomially_longer, attempts: 3

  def perform(location_id, days: Forecasts::Fetch::MAX_DAYS)
    location = Location.find(location_id)
    Forecasts::Fetch.new.call(location:, days:, refresh: true)
  end
end
