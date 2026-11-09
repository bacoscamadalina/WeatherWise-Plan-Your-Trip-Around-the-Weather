require "test_helper"

class RefreshLocationForecastJobTest < ActiveJob::TestCase
  test "forces a full forecast refresh for one location" do
    location = create_location("refresh-one")
    previous_provider = ENV["WEATHER_PROVIDER"]
    ENV["WEATHER_PROVIDER"] = "mock"

    RefreshLocationForecastJob.perform_now(location.id, days: 7)

    assert_equal 7, location.daily_forecasts.where(provider: "mock").count
    assert_equal Date.current, location.daily_forecasts.minimum(:forecast_date)
  ensure
    ENV["WEATHER_PROVIDER"] = previous_provider
  end

  private

  def create_location(external_id)
    Location.create!(
      name: "Iași",
      country_code: "RO",
      latitude: 47.1585,
      longitude: 27.6014,
      timezone: "Europe/Bucharest",
      provider: "test",
      external_id:
    )
  end
end
