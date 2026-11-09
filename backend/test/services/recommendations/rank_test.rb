require "test_helper"

class Recommendations::RankTest < ActiveSupport::TestCase
  setup do
    @location = Location.create!(
      name: "Iași", country_code: "RO", latitude: 47.1585, longitude: 27.6014,
      timezone: "Europe/Bucharest", provider: "test", external_id: "iasi-rank"
    )
    @forecast = @location.daily_forecasts.create!(
      forecast_date: Date.current, provider: "test", condition_code: "61",
      condition_label: "Rain", weather_class: "rain", activity_context: "indoor",
      temperature_min_c: 8, temperature_max_c: 14, precipitation_probability: 80,
      precipitation_mm: 6, wind_speed_kph: 12, fetched_at: Time.current
    )
    @museum = Recommendation.create!(
      location: @location, recommendation_type: "activity", title: "Museum",
      summary: "Indoor culture", indoor: true, provider: "test", external_id: "museum",
      tags: %w[culture museum], weather_classes: %w[rain],
      metadata: { latitude: 47.1575, longitude: 27.5869 }
    )
    @park = Recommendation.create!(
      location: @location, recommendation_type: "activity", title: "Park",
      summary: "Outdoor walk", indoor: false, provider: "test", external_id: "park",
      tags: %w[nature park], weather_classes: %w[clear],
      metadata: { latitude: 48.0, longitude: 27.6014 }
    )
    @movie = Recommendation.create!(
      recommendation_type: "movie", title: "Mystery Film", summary: "Indoor film",
      indoor: true, provider: "test", external_id: "mystery-film", genres: %w[noir-test],
      weather_classes: %w[rain]
    )
  end

  test "ranks sheltered weather matches first on a rainy day" do
    results = Recommendations::Rank.new.call(forecast: @forecast)

    assert_equal @museum, results.first.recommendation
    assert_operator results.first.score, :>, results.last.score
    assert_match(/sheltered choice/, results.first.reason)
  end

  test "localizes WeatherWise recommendation guidance in Romanian" do
    results = Recommendations::Rank.new.call(forecast: @forecast, language: "ro")

    assert_equal @museum, results.first.recommendation
    assert_match(/alegere la adăpost/, results.first.reason)
  end

  test "filters by type and genre" do
    results = Recommendations::Rank.new.call(forecast: @forecast, type: "movie", genre: "noir-test")

    assert_equal [ @movie ], results.map(&:recommendation)
    assert_match(/Noir Test movie mood/, results.first.reason)
  end

  test "curates movies by weather, date, and location personality" do
    comedy = Recommendation.create!(
      recommendation_type: "movie", title: "Sunny Comedy", summary: "Bright comedy",
      indoor: true, provider: "test", external_id: "sunny-comedy", genres: %w[comedy romance],
      weather_classes: %w[clear]
    )

    rainy = Recommendations::Rank.new.call(forecast: @forecast, type: "movie")

    assert_equal @movie, rainy.first.recommendation
    assert_operator rainy.first.score, :>, rainy.find { |result| result.recommendation == comedy }.score
    assert_match(/Iași/, rainy.first.reason)
    assert_match(/rhythm of the rain/, rainy.first.reason)
  end

  test "excludes movies already shown in another day or location" do
    results = Recommendations::Rank.new.call(
      forecast: @forecast,
      type: "movie",
      excluded_movie_ids: [ @movie.id ]
    )

    assert_not_includes results.map(&:recommendation), @movie
  end

  test "gives the localized movie selection a place-specific voice" do
    result = Recommendations::Rank.new.call(
      forecast: @forecast,
      type: "movie",
      language: "ro"
    ).first

    assert_match(/Iași/, result.reason)
    assert_match(/ritmul ploii/, result.reason)
  end

  test "filters activities by style setting and distance" do
    results = Recommendations::Rank.new.call(
      forecast: @forecast,
      type: "activity",
      activity_kind: "culture",
      setting: "indoor",
      max_distance_km: 2
    )

    assert_equal [ @museum ], results.map(&:recommendation)
    assert_in_delta 1.1, results.first.distance_km, 0.2
    assert_match(/culture pick/, results.first.reason)
  end

  test "filters activities against any selected trip interest" do
    results = Recommendations::Rank.new.call(
      forecast: @forecast,
      activity_kinds: %w[culture entertainment]
    )

    assert_includes results.map(&:recommendation), @museum
    assert_includes results.map(&:recommendation), @movie
    assert_not_includes results.map(&:recommendation), @park
  end

  test "distance filter excludes remote activities" do
    results = Recommendations::Rank.new.call(
      forecast: @forecast,
      type: "activity",
      max_distance_km: 5
    )

    assert_includes results.map(&:recommendation), @museum
    assert_not_includes results.map(&:recommendation), @park
  end

  test "filters and explains recommendations by time of day" do
    results = Recommendations::Rank.new.call(
      forecast: @forecast,
      time_of_day: "evening"
    )

    assert_equal [ @movie ], results.map(&:recommendation)
    assert_equal [ "evening" ], results.first.recommended_periods
    assert_match(/evening plan/, results.first.reason)
  end

  test "excludes activities listed as closed in the requested period" do
    @museum.update!(metadata: @museum.metadata.merge(opening_hours: "Mo-Su 10:00-13:00"))

    results = Recommendations::Rank.new.call(
      forecast: @forecast,
      type: "activity",
      activity_kind: "culture",
      time_of_day: "afternoon"
    )

    assert_empty results
  end

  test "penalizes exposed outdoor ideas and explains very high UV" do
    @forecast.update!(
      condition_code: "0", condition_label: "Clear", weather_class: "clear",
      activity_context: "outdoor", precipitation_probability: 0,
      uv_index_max: 7
    )
    baseline = Recommendations::Rank.new.call(forecast: @forecast, type: "activity")
    baseline_park = baseline.find { |result| result.recommendation == @park }

    @forecast.update!(uv_index_max: 8.5)
    exposed = Recommendations::Rank.new.call(forecast: @forecast, type: "activity")
    exposed_park = exposed.find { |result| result.recommendation == @park }
    sheltered_museum = exposed.find { |result| result.recommendation == @museum }

    assert_equal baseline_park.score - 6, exposed_park.score
    assert_equal "very_high_uv", exposed_park.planning_notes.first[:code]
    assert_equal "moderate", exposed_park.planning_notes.first[:severity]
    assert_match(/UV peaks at 8.5/, exposed_park.planning_notes.first[:message])
    assert_empty sheltered_museum.planning_notes
  end

  test "localizes UV planning guidance in Romanian" do
    @forecast.update!(
      condition_code: "0", condition_label: "Clear", weather_class: "clear",
      activity_context: "outdoor", precipitation_probability: 0,
      uv_index_max: 8.5
    )

    result = Recommendations::Rank.new.call(forecast: @forecast, type: "activity", language: "ro")
      .find { |suggestion| suggestion.recommendation == @park }

    assert_match(/Indicele UV ajunge la 8.5/, result.planning_notes.first[:message])
  end

  test "never recommends a weather-sensitive hike on a rainy day" do
    hike = create_hike

    results = Recommendations::Rank.new.call(
      forecast: @forecast, type: "activity", activity_kind: "nature"
    )

    assert_not_includes results.map(&:recommendation), hike
  end

  test "recommends a nearby hike only with dry weather wind and enough daylight" do
    hike = create_hike
    @forecast.update!(
      condition_code: "1", condition_label: "Mainly clear", weather_class: "clear",
      activity_context: "outdoor", precipitation_probability: 10, precipitation_mm: 0,
      wind_speed_kph: 18, sunrise_local: "2026-10-07T07:30",
      sunset_local: "2026-10-07T18:30", daylight_duration_seconds: 39_600
    )

    result = Recommendations::Rank.new.call(
      forecast: @forecast, type: "activity", activity_kind: "nature", language: "ro"
    ).find { |suggestion| suggestion.recommendation == hike }

    assert result
    assert_equal "verify_trail_conditions", result.planning_notes.first[:code]
    assert_match(/11.0 ore de lumină/, result.planning_notes.first[:message])
    assert_match(/Prognoza locală pentru Iași/, result.planning_notes.first[:message])
    assert_match(/Nu verifică vremea pe traseu sau la altitudine/, result.planning_notes.first[:message])
    assert_match(/condițiile montane rămân neverificate/, result.reason)
  end

  test "hides a hike when the daylight window is too short" do
    hike = create_hike
    @forecast.update!(
      condition_code: "1", condition_label: "Mainly clear", weather_class: "clear",
      activity_context: "outdoor", precipitation_probability: 5, precipitation_mm: 0,
      wind_speed_kph: 10, sunrise_local: "2026-12-20T09:00",
      sunset_local: "2026-12-20T15:30", daylight_duration_seconds: 23_400
    )

    results = Recommendations::Rank.new.call(forecast: @forecast, type: "activity")

    assert_not_includes results.map(&:recommendation), hike
  end

  test "balances activity categories before repeating similar mountain results" do
    @forecast.update!(
      condition_code: "1", condition_label: "Mainly clear", weather_class: "clear",
      activity_context: "outdoor", precipitation_probability: 5, precipitation_mm: 0,
      wind_speed_kph: 10, sunrise_local: "2026-10-07T07:30",
      sunset_local: "2026-10-07T18:30", daylight_duration_seconds: 39_600
    )
    3.times do |index|
      Recommendation.create!(
        location: @location, recommendation_type: "activity", title: "Summit #{index}",
        summary: "Mapped summit", indoor: false, provider: "test", external_id: "summit-#{index}",
        tags: %w[nature hiking summit peak], weather_classes: %w[clear cloudy],
        metadata: {
          distance_km: index + 1, weather_sensitivity: "dry_daylight",
          activity_kind: "nature", activity_category: "peak", elevation_m: 2_000 - index
        }
      )
    end
    Recommendation.create!(
      location: @location, recommendation_type: "activity", title: "Mountain trail",
      summary: "Mapped trail", indoor: false, provider: "test", external_id: "mountain-trail",
      tags: %w[nature hiking route trail], weather_classes: %w[clear cloudy],
      metadata: {
        distance_km: 4, weather_sensitivity: "dry_daylight",
        activity_kind: "nature", activity_category: "trail"
      }
    )
    Recommendation.create!(
      location: @location, recommendation_type: "activity", title: "Valley viewpoint",
      summary: "Mapped viewpoint", indoor: false, provider: "test", external_id: "valley-viewpoint",
      tags: %w[nature viewpoint], weather_classes: %w[clear cloudy],
      metadata: {
        distance_km: 5, weather_sensitivity: "outdoor_daylight",
        activity_kind: "nature", activity_category: "viewpoint"
      }
    )

    results = Recommendations::Rank.new.call(forecast: @forecast, type: "activity", limit: 4)
    titles = results.map { |result| result.recommendation.title }

    assert_equal 1, titles.count { |title| title.start_with?("Summit") }
    assert_includes titles, "Mountain trail"
    assert_includes titles, "Valley viewpoint"
  end

  private

  def create_hike
    Recommendation.create!(
      location: @location, recommendation_type: "activity", title: "Vârful Toaca",
      summary: "Summit hike", indoor: false, provider: "test",
      external_id: "peak-toaca", tags: %w[nature hiking summit], weather_classes: %w[clear cloudy],
      metadata: {
        latitude: 47.0, longitude: 27.0, distance_km: 18.0,
        weather_sensitivity: "dry_daylight", activity_kind: "nature", elevation_m: 1904
      }
    )
  end
end
