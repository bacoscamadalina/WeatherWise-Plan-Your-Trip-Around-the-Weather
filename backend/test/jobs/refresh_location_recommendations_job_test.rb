require "test_helper"

class RefreshLocationRecommendationsJobTest < ActiveJob::TestCase
  RecordingProvider = Struct.new(:requests) do
    def suggestions(request:)
      requests << request
    end
  end

  test "rebuilds a provider request for the selected location and forecast" do
    location = Location.create!(
      name: "Iași", country_code: "RO", latitude: 47.1585, longitude: 27.6014,
      provider: "test", external_id: "iasi-refresh-recommendations"
    )
    forecast = DailyForecast.create!(
      location:, forecast_date: Date.current, provider: "test",
      condition_code: "1", condition_label: "Mainly clear", weather_class: "clear",
      activity_context: "outdoor", temperature_min_c: 10, temperature_max_c: 22,
      precipitation_probability: 5, precipitation_mm: 0, wind_speed_kph: 8,
      fetched_at: Time.current
    )
    provider = RecordingProvider.new([])
    job = RefreshLocationRecommendationsJob.new
    job.define_singleton_method(:provider) { provider }

    job.perform(location:, forecast:, type: "activity", language: "ro")

    request = provider.requests.fetch(0)
    assert_equal location, request.location
    assert_equal forecast, request.forecast
    assert_equal "activity", request.preferences.fetch(:type)
    assert_equal "ro", request.preferences.fetch(:language)
  end
end
