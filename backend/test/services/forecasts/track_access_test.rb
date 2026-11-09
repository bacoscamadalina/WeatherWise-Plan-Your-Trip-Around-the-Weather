require "test_helper"

class Forecasts::TrackAccessTest < ActiveSupport::TestCase
  setup do
    @location = Location.create!(
      name: "Iași",
      country_code: "RO",
      latitude: 47.1585,
      longitude: 27.6014,
      timezone: "Europe/Bucharest",
      provider: "test",
      external_id: "iasi-access"
    )
  end

  test "aggregates requests into one daily access bucket" do
    at = Time.zone.parse("2026-10-01 09:00")

    2.times { Forecasts::TrackAccess.new.call(location: @location, at:) }

    access = @location.forecast_accesses.sole
    assert_equal Date.new(2026, 10, 1), access.accessed_on
    assert_equal 2, access.request_count
    assert_equal at, access.last_accessed_at
  end

  test "starts a new bucket on the next day" do
    service = Forecasts::TrackAccess.new
    service.call(location: @location, at: Time.zone.parse("2026-10-01 23:50"))
    service.call(location: @location, at: Time.zone.parse("2026-10-02 00:10"))

    assert_equal 2, @location.forecast_accesses.count
    assert_equal [ 1, 1 ], @location.forecast_accesses.order(:accessed_on).pluck(:request_count)
  end
end
