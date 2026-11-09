require "test_helper"

class RefreshPopularForecastsJobTest < ActiveJob::TestCase
  setup do
    @popular = create_location("popular")
    @quiet = create_location("quiet")
    @old = create_location("old")

    create_access(@popular, Date.new(2026, 10, 1), 2)
    create_access(@popular, Date.new(2026, 10, 2), 2)
    create_access(@quiet, Date.new(2026, 10, 2), 2)
    create_access(@old, Date.new(2026, 8, 1), 10)
  end

  test "enqueues refreshes only for recently popular locations" do
    assert_enqueued_jobs 1, only: RefreshLocationForecastJob do
      RefreshPopularForecastsJob.perform_now(
        as_of: Date.new(2026, 10, 2),
        lookback_days: 2,
        min_requests: 3,
        days: 10
      )
    end

    job = enqueued_jobs.find { |item| item[:job] == RefreshLocationForecastJob }
    assert_equal @popular.id, job.fetch(:args).first
  end

  test "removes access buckets outside the retention window" do
    RefreshPopularForecastsJob.perform_now(
      as_of: Date.new(2026, 10, 2),
      lookback_days: 2,
      min_requests: 3
    )

    assert_not ForecastAccess.exists?(location: @old)
    assert ForecastAccess.exists?(location: @popular)
  end

  private

  def create_location(external_id)
    Location.create!(
      name: external_id.titleize,
      country_code: "RO",
      latitude: 47.1585,
      longitude: 27.6014,
      timezone: "Europe/Bucharest",
      provider: "test",
      external_id:
    )
  end

  def create_access(location, accessed_on, request_count)
    ForecastAccess.create!(
      location:,
      accessed_on:,
      request_count:,
      last_accessed_at: accessed_on.noon
    )
  end
end
