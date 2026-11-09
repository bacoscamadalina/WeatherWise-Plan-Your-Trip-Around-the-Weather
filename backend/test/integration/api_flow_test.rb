require "test_helper"

class ApiFlowTest < ActionDispatch::IntegrationTest
  test "searches for a location and returns a fourteen day forecast" do
    get "/api/v1/locations/search", params: { q: "Iasi" }
    assert_response :success
    location_id = response.parsed_body.dig("data", 0, "id")

    get "/api/v1/locations/#{location_id}/forecasts", params: { days: 14 }
    assert_response :success
    body = response.parsed_body
    assert_equal "Iași", body.dig("data", "location", "name")
    assert_equal 14, body.dig("data", "forecasts").size
    assert_includes %w[indoor outdoor flexible caution], body.dig("data", "forecasts", 0, "activity_context")
    assert_equal [], body.dig("data", "forecasts", 0, "advisories")
    assert_equal "rain", body.dig("data", "forecasts", 1, "advisories", 0, "code")
    assert_equal "moderate", body.dig("data", "forecasts", 1, "advisories", 0, "severity")
    assert_equal 4.2, body.dig("data", "forecasts", 0, "uv_index_max")
    first_date = body.dig("data", "forecasts", 0, "date")
    assert_equal "#{first_date}T07:15", body.dig("data", "forecasts", 0, "daylight", "sunrise_local")
    assert_equal 41_400, body.dig("data", "forecasts", 0, "daylight", "duration_seconds")
    assert body.dig("meta", "forecast_updated_at").present?
    assert Time.iso8601(body.dig("meta", "forecast_updated_at"))

    forecast_id = body.dig("data", "forecasts", 0, "id")
    assert_nil body.dig("data", "forecasts", 0, "current")
    DailyForecast.find(forecast_id).update!(
      raw_data: {
        current: {
          time: "2026-10-02T16:15",
          weather_code: 1,
          temperature_c: 19.7,
          apparent_temperature_c: 16.3,
          precipitation_mm: 0,
          wind_speed_kph: 13.7,
          daylight: true
        }
      }
    )
    get "/api/v1/locations/#{location_id}/forecasts", params: { days: 14 }
    assert_response :success
    current = response.parsed_body.dig("data", "forecasts", 0, "current")
    assert_equal "2026-10-02T16:15", current.fetch("observed_at")
    assert_equal "Mainly clear", current.dig("condition", "label")
    assert_equal "clear", current.dig("condition", "weather_class")
    assert_equal 19.7, current.fetch("temperature_c")
    assert_equal 16.3, current.fetch("apparent_temperature_c")
    assert_equal 13.7, current.fetch("wind_speed_kph")
    assert current.fetch("daylight")

    Recommendation.create!(
      location_id:, recommendation_type: "activity", title: "Palace of Culture",
      summary: "Indoor museum visit", indoor: true, provider: "openstreetmap", external_id: "api-palace",
      weather_classes: %w[rain cloudy], tags: %w[museum culture],
      metadata: {
        distance_km: 1.4, opening_hours: "24/7",
        latitude: 47.1575, longitude: 27.5869, language: "en"
      }
    )
    get "/api/v1/forecasts/#{forecast_id}/recommendations", params: {
      type: "activity", activity_kind: "culture", setting: "indoor", max_distance_km: 2,
      time_of_day: "afternoon"
    }
    assert_response :success
    assert_equal "Palace of Culture", response.parsed_body.dig("data", "recommendations", 0, "title")
    assert response.parsed_body.dig("data", "recommendations", 0, "reason").present?
    assert_equal [], response.parsed_body.dig("data", "recommendations", 0, "planning_notes")
    assert_equal 1.4, response.parsed_body.dig("data", "recommendations", 0, "distance_km")
    assert_equal 47.1575, response.parsed_body.dig("data", "recommendations", 0, "coordinates", "latitude")
    assert_equal "© OpenStreetMap contributors", response.parsed_body.dig("data", "recommendations", 0, "attribution", "label")
    assert_equal "culture", response.parsed_body.dig("meta", "filters", "activity_kind")
    assert_equal "indoor", response.parsed_body.dig("meta", "filters", "setting")
    assert_equal 2.0, response.parsed_body.dig("meta", "filters", "max_distance_km")
    assert_equal "afternoon", response.parsed_body.dig("meta", "filters", "time_of_day")
    assert_includes response.parsed_body.dig("data", "recommendations", 0, "recommended_periods"), "afternoon"
    assert_equal "listed_open", response.parsed_body.dig("data", "recommendations", 0, "availability", "status")

    get "/api/v1/forecasts/#{forecast_id}/hourly"
    assert_response :success
    assert_equal 24, response.parsed_body.dig("data", "hours").size
    assert_equal "Europe/Bucharest", response.parsed_body.dig("data", "timezone")
    assert_match(/T00:00:00\+03:00\z/, response.parsed_body.dig("data", "hours", 0, "time"))
    assert_equal "#{first_date}T00:00:00", response.parsed_body.dig("data", "hours", 0, "local_time")
    assert_includes %w[indoor outdoor flexible caution],
      response.parsed_body.dig("data", "hours", 0, "activity_context")

    get "/api/v1/locations/#{location_id}/event_days", params: {
      start_date: first_date,
      end_date: (Date.iso8601(first_date) + 13.days).iso8601
    }
    assert_response :success
    assert_equal first_date, response.parsed_body.dig("meta", "start_date")
    assert_equal [], response.parsed_body.fetch("data")
  end

  test "rejects an undersized query" do
    get "/api/v1/locations/search", params: { q: "I" }

    assert_response :unprocessable_content
    assert_equal "invalid_query", response.parsed_body.dig("error", "code")
  end

  test "returns locale and pagination metadata for location search" do
    get "/api/v1/locations/search",
      params: { q: "Jassy", page: 1, per_page: 3 },
      headers: { "Accept-Language" => "ro-RO,ro;q=0.9" }

    assert_response :success
    assert_equal "Iași", response.parsed_body.dig("data", 0, "name")
    assert_equal "ro", response.parsed_body.dig("meta", "language")
    assert_equal 1, response.parsed_body.dig("meta", "page")
    assert_equal 3, response.parsed_body.dig("meta", "per_page")
    assert_equal false, response.parsed_body.dig("meta", "has_more")
    assert_equal "Location data by GeoNames via Open-Meteo",
      response.parsed_body.dig("meta", "attribution", "label")
  end

  test "localizes WeatherWise-owned offline movie summaries" do
    location = Locations::Search.new.call(query: "Iasi").first
    forecast = Forecasts::Fetch.new.call(location:, days: 1).first
    movie = Recommendation.create!(
      recommendation_type: "movie", title: "Offline Film", summary: "English summary",
      indoor: true, provider: "seed", external_id: "localized-offline-film",
      weather_classes: [ forecast.weather_class ],
      metadata: { translations: { ro: { summary: "Descriere în limba română." } } }
    )

    get "/api/v1/forecasts/#{forecast.id}/recommendations", params: { type: "movie", language: "ro", limit: 20 }

    assert_response :success
    result = response.parsed_body.dig("data", "recommendations").find { |item| item["id"] == movie.id }
    assert_equal "Descriere în limba română.", result.fetch("summary")
  end

  test "rejects an invalid recommendation type" do
    location = Locations::Search.new.call(query: "Iasi").first
    forecast = Forecasts::Fetch.new.call(location:, days: 1).first

    get "/api/v1/forecasts/#{forecast.id}/recommendations", params: { type: "restaurant" }

    assert_response :bad_request
    assert_equal "bad_request", response.parsed_body.dig("error", "code")
  end

  test "returns date-scoped events and a provider-neutral showtime response" do
    location = Locations::Search.new.call(query: "Iasi").first
    forecast = Forecasts::Fetch.new.call(location:, days: 1).first
    event = Recommendation.create!(
      location:, recommendation_type: "event", title: "Evening Concert",
      summary: "A local event", indoor: true, provider: "test", external_id: "event-api",
      tags: %w[event setting-unverified], weather_classes: %w[clear rain],
      metadata: {
        event_date: forecast.forecast_date.iso8601,
        event_time: "19:30:00",
        event_status: "onsale",
        setting: "unknown"
      }
    )

    get "/api/v1/forecasts/#{forecast.id}/recommendations", params: { type: "event", time_of_day: "evening" }
    assert_response :success
    assert_equal event.id, response.parsed_body.dig("data", "recommendations", 0, "id")
    assert_equal "19:30:00", response.parsed_body.dig("data", "recommendations", 0, "event_time")

    get "/api/v1/forecasts/#{forecast.id}/showtimes"
    assert_response :success
    assert_equal [], response.parsed_body.dig("data", "showtimes")
    assert_equal "database", response.parsed_body.dig("meta", "provider")
    assert_equal false, response.parsed_body.dig("meta", "live")

    get "/api/v1/forecasts/#{forecast.id}/showtimes/booking_link", params: {
      film_id: "7", cinema_id: "9", time: "19:30"
    }
    assert_response :not_found
    assert_equal "booking_link_unavailable", response.parsed_body.dig("error", "code")

    get "/api/v1/forecasts/#{forecast.id}/showtimes/booking_link", params: {
      film_id: "bad", cinema_id: "9", time: "19:30"
    }
    assert_response :bad_request
  end

  test "rejects invalid recommendation refinements" do
    location = Locations::Search.new.call(query: "Iasi").first
    forecast = Forecasts::Fetch.new.call(location:, days: 1).first

    get "/api/v1/forecasts/#{forecast.id}/recommendations", params: { setting: "underwater" }
    assert_response :bad_request

    get "/api/v1/forecasts/#{forecast.id}/recommendations", params: { activity_kind: "shopping" }
    assert_response :bad_request

    get "/api/v1/forecasts/#{forecast.id}/recommendations", params: { max_distance_km: 100 }
    assert_response :bad_request

    get "/api/v1/forecasts/#{forecast.id}/recommendations", params: { time_of_day: "midnight" }
    assert_response :bad_request
  end

  test "excludes movie ids already shown by the client" do
    location = Locations::Search.new.call(query: "Iasi").first
    forecast = Forecasts::Fetch.new.call(location:, days: 1).first
    movie = Recommendation.create!(
      recommendation_type: "movie", title: "Already Seen", summary: "Seen elsewhere",
      indoor: true, provider: "test", external_id: "already-seen-movie",
      genres: %w[drama], weather_classes: %w[rain]
    )

    get "/api/v1/forecasts/#{forecast.id}/recommendations", params: {
      type: "movie", exclude_movie_ids: movie.id
    }

    assert_response :success
    ids = response.parsed_body.dig("data", "recommendations").pluck("id")
    assert_not_includes ids, movie.id
    assert response.parsed_body.dig("meta", "movie_personality").present?
  end

  test "limits the number of excluded movie ids" do
    location = Locations::Search.new.call(query: "Iasi").first
    forecast = Forecasts::Fetch.new.call(location:, days: 1).first
    get "/api/v1/forecasts/#{forecast.id}/recommendations", params: {
      type: "movie", exclude_movie_ids: (1..101).to_a.join(",")
    }

    assert_response :bad_request
  end

  test "returns a graceful activity availability fallback" do
    location = Locations::Search.new.call(query: "Iasi").first
    forecast = Forecasts::Fetch.new.call(location:, days: 1).first
    activity = Recommendation.create!(
      location:, recommendation_type: "activity", title: "Test Museum",
      venue_name: "Test Museum", summary: "Indoor culture", indoor: true,
      provider: "test", external_id: "availability-api", tags: %w[museum],
      metadata: { latitude: 47.1575, longitude: 27.5869 }
    )

    get "/api/v1/forecasts/#{forecast.id}/recommendations/#{activity.id}/availability",
      params: { period: "afternoon" }

    assert_response :success
    assert_equal "not_configured", response.parsed_body.dig("data", "status")
    assert_equal "afternoon", response.parsed_body.dig("data", "period")
    assert_equal false, response.parsed_body.dig("meta", "live")

    get "/api/v1/forecasts/#{forecast.id}/recommendations/#{activity.id}/availability",
      params: { period: "midnight" }
    assert_response :bad_request
  end
end
