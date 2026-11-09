require "test_helper"

class Recommendations::TimingTest < ActiveSupport::TestCase
  setup do
    @timing = Recommendations::Timing.new
    @activity = Recommendation.new(
      recommendation_type: "activity",
      title: "Museum",
      summary: "Indoor culture",
      indoor: true,
      provider: "test",
      external_id: "timing-museum",
      tags: %w[museum culture]
    )
  end

  test "infers practical periods by recommendation kind" do
    assert_equal %w[morning afternoon], @timing.periods(@activity)

    movie = @activity.dup
    movie.recommendation_type = "movie"
    assert_equal [ "evening" ], @timing.periods(movie)
  end

  test "interprets a simple provider schedule conservatively" do
    @activity.metadata = { opening_hours: "Tu-Su 10:00-17:00" }

    open_result = @timing.availability(
      item: @activity,
      date: Date.new(2026, 10, 2),
      period: "afternoon"
    )
    closed_result = @timing.availability(
      item: @activity,
      date: Date.new(2026, 10, 5),
      period: "afternoon"
    )

    assert_equal "listed_open", open_result[:status]
    assert_equal "listed_closed", closed_result[:status]
  end

  test "marks complex schedules for verification" do
    @activity.metadata = { opening_hours: "sunrise-sunset" }

    result = @timing.availability(
      item: @activity,
      date: Date.new(2026, 10, 2),
      period: "morning"
    )

    assert_equal "check_required", result[:status]
    assert_match(/Verify before visiting/, result[:disclaimer])
  end

  test "does not trust malformed provider times" do
    @activity.metadata = { opening_hours: "Mo-Su 10:00-29:00" }

    result = @timing.availability(
      item: @activity,
      date: Date.new(2026, 10, 2),
      period: "afternoon"
    )

    assert_equal "check_required", result[:status]
  end

  test "does not attach place hours guidance to movies" do
    @activity.recommendation_type = "movie"

    assert_nil @timing.availability(
      item: @activity,
      date: Date.new(2026, 10, 2),
      period: "evening"
    )
  end
end
