require "test_helper"

class Recommendations::CacheFirstProviderTest < ActiveSupport::TestCase
  RecordingJob = Struct.new(:calls) do
    def perform_later(**arguments)
      calls << arguments
    end
  end

  setup do
    @location = Location.create!(
      name: "Iași", country_code: "RO", latitude: 47.1585, longitude: 27.6014,
      provider: "test", external_id: "iasi-cache-first"
    )
    @forecast = DailyForecast.create!(
      location: @location, forecast_date: Date.current, provider: "test",
      condition_code: "1", condition_label: "Mainly clear", weather_class: "clear",
      activity_context: "outdoor", temperature_min_c: 10, temperature_max_c: 22,
      precipitation_probability: 5, precipitation_mm: 0, wind_speed_kph: 8,
      fetched_at: Time.current
    )
    @recommendation = Recommendation.create!(
      location: @location, recommendation_type: "activity", title: "Palatul Culturii",
      summary: "Vizită culturală", indoor: true, provider: "test", external_id: "palace",
      weather_classes: %w[clear rain]
    )
  end

  test "returns the local catalog immediately and schedules a live refresh" do
    job = RecordingJob.new([])
    request = Recommendations::Request.new(
      location: @location,
      forecast: @forecast,
      preferences: { type: "activity", language: "ro" }
    )
    provider = Recommendations::CacheFirstProvider.new(refresh_job: job)

    assert_equal [ @recommendation ], provider.suggestions(request:)
    assert_equal 1, job.calls.size
    assert_equal @location, job.calls.first.fetch(:location)
    assert_equal @forecast, job.calls.first.fetch(:forecast)
    assert_equal "activity", job.calls.first.fetch(:type)
    assert_equal "ro", job.calls.first.fetch(:language)
  end
end
