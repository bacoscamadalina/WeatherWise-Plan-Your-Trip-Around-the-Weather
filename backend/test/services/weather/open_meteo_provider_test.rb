require "test_helper"

class Weather::OpenMeteoProviderTest < ActiveSupport::TestCase
  class FakeClient
    attr_reader :uri

    def get_json(uri)
      @uri = uri
      {
        "current" => {
          "time" => "2026-10-01T16:15",
          "temperature_2m" => 19.7,
          "apparent_temperature" => 16.3,
          "precipitation" => 0.0,
          "weather_code" => 1,
          "wind_speed_10m" => 13.7,
          "is_day" => 1
        },
        "daily" => {
          "time" => %w[2026-10-01 2026-10-02],
          "weather_code" => [ 1, 61 ],
          "temperature_2m_min" => [ 10.2, 8.1 ],
          "temperature_2m_max" => [ 20.4, 14.3 ],
          "precipitation_probability_max" => [ 10, 80 ],
          "precipitation_sum" => [ 0.0, 6.4 ],
          "wind_speed_10m_max" => [ 8.5, 13.2 ],
          "uv_index_max" => [ 4.2, 2.6 ],
          "sunrise" => %w[2026-10-01T07:12 2026-10-02T07:13],
          "sunset" => %w[2026-10-01T18:51 2026-10-02T18:49],
          "daylight_duration" => [ 41_940, 41_760 ]
        }
      }
    end
  end

  class HourlyFakeClient
    attr_reader :uri

    def get_json(uri)
      @uri = uri
      {
        "hourly" => {
          "time" => %w[2026-10-02T08:00 2026-10-02T09:00],
          "weather_code" => [ 61, 3 ],
          "temperature_2m" => [ 10.2, 11.1 ],
          "precipitation_probability" => [ 80, 35 ],
          "precipitation" => [ 1.2, 0.1 ],
          "wind_speed_10m" => [ 14.0, 12.4 ],
          "is_day" => [ 1, 1 ]
        }
      }
    end
  end

  test "maps daily arrays to one normalized input hash per day" do
    client = FakeClient.new
    location = Struct.new(:latitude, :longitude, :timezone).new(47.1585, 27.6014, "Europe/Bucharest")
    results = Weather::OpenMeteoProvider.new(client:).daily_forecast(location:, days: 2)

    assert_equal 2, results.size
    assert_equal 61, results.second[:weather_code]
    assert_equal 80, results.second[:precipitation_probability]
    assert_equal 6.4, results.second[:precipitation_mm]
    assert_equal 2.6, results.second[:uv_index_max]
    assert_equal "2026-10-02T07:13", results.second[:sunrise_local]
    assert_equal 41_760, results.second[:daylight_duration_seconds]
    assert_equal 19.7, results.first.dig(:current, :temperature_c)
    assert_equal 16.3, results.first.dig(:current, :apparent_temperature_c)
    assert_nil results.second[:current]

    query = URI.decode_www_form(client.uri.query).to_h
    assert_equal "2", query.fetch("forecast_days")
    assert_equal "Europe/Bucharest", query.fetch("timezone")
    assert_includes query.fetch("daily"), "weather_code"
    assert_includes query.fetch("daily"), "uv_index_max"
    assert_includes query.fetch("daily"), "daylight_duration"
    assert_includes query.fetch("current"), "temperature_2m"
    assert_includes query.fetch("current"), "apparent_temperature"
  end

  test "maps hourly arrays and scopes the request to the selected local date" do
    client = HourlyFakeClient.new
    location = Struct.new(:latitude, :longitude, :timezone).new(47.1585, 27.6014, "Europe/Bucharest")
    results = Weather::OpenMeteoProvider.new(client:).hourly_forecast(
      location:, date: Date.new(2026, 10, 2)
    )

    assert_equal 2, results.size
    assert_equal "2026-10-02T08:00", results.first[:time]
    assert_equal 80, results.first[:precipitation_probability]
    assert results.first[:daylight]

    query = URI.decode_www_form(client.uri.query).to_h
    assert_equal "2026-10-02", query.fetch("start_date")
    assert_equal "2026-10-02", query.fetch("end_date")
    assert_equal "Europe/Bucharest", query.fetch("timezone")
    assert_includes query.fetch("hourly"), "temperature_2m"
  end
end
