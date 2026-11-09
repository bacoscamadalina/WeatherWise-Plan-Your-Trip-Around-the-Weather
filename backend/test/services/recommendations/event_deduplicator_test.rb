require "test_helper"

class Recommendations::EventDeduplicatorTest < ActiveSupport::TestCase
  test "keeps the richest listing when two providers publish the same event" do
    weak = event(provider: "predicthq", url: nil, metadata: { "event_date" => "2026-10-06", "event_time" => "19:00:00" })
    rich = event(
      provider: "ticketmaster",
      url: "https://example.test/tickets",
      metadata: { "event_date" => "2026-10-06", "event_time" => "19:00:00", "image_url" => "https://example.test/poster.jpg" }
    )

    result = Recommendations::EventDeduplicator.new.call([ weak, rich ])

    assert_equal [ rich ], result
  end

  private

  def event(provider:, url:, metadata:)
    Recommendation.new(
      recommendation_type: "event", title: "Autumn – Festival", summary: "Live",
      indoor: true, provider:, external_id: provider, url:, weather_classes: %w[clear],
      metadata:
    )
  end
end
