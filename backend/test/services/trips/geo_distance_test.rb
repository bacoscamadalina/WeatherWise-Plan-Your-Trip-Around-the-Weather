require "test_helper"

class Trips::GeoDistanceTest < ActiveSupport::TestCase
  test "calculates a stable distance between two coordinates" do
    distance = Trips::GeoDistance.km(
      { latitude: 47.1585, longitude: 27.6014 },
      { latitude: 47.1747, longitude: 27.5719 }
    )

    assert_in_delta 2.9, distance, 0.2
  end

  test "returns nil when either point has no coordinates" do
    assert_nil Trips::GeoDistance.km(
      { latitude: 47.1585, longitude: 27.6014 },
      { latitude: nil, longitude: nil }
    )
  end
end
