module Weather
  class MockProvider < Provider
    PATTERN = [
      { weather_code: 1, temperature_min_c: 11, temperature_max_c: 21, precipitation_probability: 10, precipitation_mm: 0, wind_speed_kph: 8 },
      { weather_code: 61, temperature_min_c: 9, temperature_max_c: 15, precipitation_probability: 80, precipitation_mm: 7.2, wind_speed_kph: 14 },
      { weather_code: 3, temperature_min_c: 10, temperature_max_c: 17, precipitation_probability: 35, precipitation_mm: 0.5, wind_speed_kph: 10 },
      { weather_code: 0, temperature_min_c: 12, temperature_max_c: 23, precipitation_probability: 5, precipitation_mm: 0, wind_speed_kph: 6 },
      { weather_code: 80, temperature_min_c: 8, temperature_max_c: 16, precipitation_probability: 60, precipitation_mm: 3.8, wind_speed_kph: 18 },
      { weather_code: 2, temperature_min_c: 10, temperature_max_c: 19, precipitation_probability: 20, precipitation_mm: 0, wind_speed_kph: 9 },
      { weather_code: 0, temperature_min_c: 13, temperature_max_c: 24, precipitation_probability: 5, precipitation_mm: 0, wind_speed_kph: 7 }
    ].freeze

    def daily_forecast(location:, days: 14)
      days.times.map do |index|
        date = Date.current + index.days
        PATTERN[index % PATTERN.length].merge(
          date:,
          uv_index_max: [ 4.2, 2.1, 3.4, 5.8, 2.8, 4.6, 6.3 ][index % PATTERN.length],
          sunrise_local: "#{date.iso8601}T07:15",
          sunset_local: "#{date.iso8601}T18:45",
          daylight_duration_seconds: 41_400
        )
      end
    end

    def hourly_forecast(location:, date:)
      24.times.map do |hour|
        rainy = hour.between?(7, 11)
        clear = hour.between?(14, 19)
        {
          time: format("%sT%02d:00", date.iso8601, hour),
          weather_code: rainy ? 61 : (clear ? 1 : 3),
          temperature_c: 9 + ([ hour, 15 ].min - 6).clamp(0, 9),
          precipitation_probability: rainy ? 78 : (clear ? 12 : 30),
          precipitation_mm: rainy ? 1.4 : 0,
          wind_speed_kph: clear ? 9 : 13,
          daylight: hour.between?(7, 19)
        }
      end
    end
  end
end
