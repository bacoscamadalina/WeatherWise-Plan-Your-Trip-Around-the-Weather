require "test_helper"

class TripsApiTest < ActionDispatch::IntegrationTest
  setup do
    @location = Location.create!(
      name: "Iași", country_code: "RO", country_name: "România",
      latitude: 47.1585, longitude: 27.6014, timezone: "Europe/Bucharest",
      provider: "test", external_id: "trips-api-iasi"
    )
    @forecast = DailyForecast.create!(
      location: @location, forecast_date: Date.current, provider: "test",
      condition_code: "1", condition_label: "Mainly clear", weather_class: "clear",
      activity_context: "outdoor", temperature_min_c: 9, temperature_max_c: 21,
      precipitation_probability: 5, precipitation_mm: 0, wind_speed_kph: 7,
      fetched_at: Time.current
    )
  end

  test "creates a persisted weather-aware trip plan" do
    post "/api/v1/trips", params: {
      language: "ro",
      trip: {
        location_id: @location.id,
        name: "Weekend în Iași",
        starts_on: Date.current.iso8601,
        ends_on: Date.current.iso8601,
        pace: "balanced",
        transport_mode: "car",
        max_distance_km: 50,
        preferences: {
          budget: "moderate", dietary: %w[vegetarian], interests: %w[culture nature]
        }
      }
    }, as: :json

    assert_response :created
    body = response.parsed_body.fetch("data")
    assert_equal "Weekend în Iași", body.fetch("name")
    assert_equal 50.0, body.fetch("max_distance_km")
    assert_equal "moderate", body.dig("preferences", "budget")
    assert_equal %w[vegetarian], body.dig("preferences", "dietary")
    assert_equal %w[culture nature], body.dig("preferences", "interests")
    assert_equal "Echilibrat", body.dig("rhythm", "label")
    assert_equal "08:30", body.dig("rhythm", "day_start")
    assert_equal 3, body.dig("rhythm", "planned_activity_count")
    assert_equal 20, body.dig("rhythm", "travel_buffer_minutes")
    assert_equal "planned", body.fetch("status")
    assert_equal 1, body.fetch("days").size
    assert_equal 6, body.dig("days", 0, "items").size
    assert_equal %w[breakfast morning lunch afternoon dinner evening],
      body.dig("days", 0, "items").pluck("slot")
    assert_equal false, body.dig("days", 0, "logistics", "route_available")
    assert_equal 0, body.dig("days", 0, "logistics", "planned_stops")
    assert_equal "dining_provider_unavailable",
      body.dig("days", 0, "items", 0, "metadata", "reason")

    get "/api/v1/trips/#{body.fetch('id')}"
    assert_response :unauthorized
  end

  test "rejects a trip longer than the forecast horizon" do
    post "/api/v1/trips", params: {
      trip: {
        location_id: @location.id,
        name: "Too long",
        starts_on: Date.current.iso8601,
        ends_on: (Date.current + 14.days).iso8601
      }
    }, as: :json

    assert_response :unprocessable_content
    assert_equal "validation_failed", response.parsed_body.dig("error", "code")
  end

  test "limits a one-day plan to the supplied arrival and departure window" do
    post "/api/v1/trips", params: {
      language: "ro",
      trip: {
        location_id: @location.id,
        name: "După-amiază în Iași",
        starts_on: Date.current.iso8601,
        ends_on: Date.current.iso8601,
        arrival_time: "14:00",
        departure_time: "19:00"
      }
    }, as: :json

    assert_response :created
    body = response.parsed_body.fetch("data")
    assert_equal "14:00", body.fetch("arrival_time")
    assert_equal "19:00", body.fetch("departure_time")
    assert_equal "14:00", body.dig("days", 0, "available_from")
    assert_equal "19:00", body.dig("days", 0, "available_until")
    assert_equal %w[afternoon], body.dig("days", 0, "items").pluck("slot")
  end

  test "rejects malformed trip clock values" do
    post "/api/v1/trips", params: {
      trip: {
        location_id: @location.id,
        name: "Invalid time",
        starts_on: Date.current.iso8601,
        ends_on: Date.current.iso8601,
        arrival_time: "tomorrow"
      }
    }, as: :json

    assert_response :bad_request
    assert_equal "bad_request", response.parsed_body.dig("error", "code")
  end

  test "does not expose or mutate an anonymous trip by sequential id" do
    trip = Trip.create!(
      location: @location, name: "Guest plan", starts_on: Date.current,
      ends_on: Date.current
    )
    day = trip.trip_days.create!(
      date: Date.current, daily_forecast: @forecast,
      weather_class: "clear", activity_context: "outdoor"
    )
    item = day.itinerary_items.create!(
      slot: "morning", kind: "free_time", title: "Guest stop", position: 1
    )

    get "/api/v1/trips/#{trip.id}"
    assert_response :unauthorized
    post "/api/v1/trips/#{trip.id}/replan", params: {
      trip: { max_distance_km: 5 }
    }, as: :json
    assert_response :unauthorized
    post "/api/v1/trips/#{trip.id}/replace_item", params: {
      item_id: item.id
    }, as: :json
    assert_response :unauthorized

    token = register("signed-in@example.com")
    get "/api/v1/trips/#{trip.id}", headers: bearer(token)
    assert_response :not_found
    assert_equal 50.0, trip.reload.max_distance_km.to_f
    assert_equal "Guest stop", item.reload.title
  end

  test "saves authenticated trips privately and lists only the owner trips" do
    owner_token = register("owner@example.com")
    other_token = register("other@example.com")

    post "/api/v1/trips", params: {
      trip: {
        location_id: @location.id,
        name: "Iași personal",
        starts_on: Date.current.iso8601,
        ends_on: Date.current.iso8601
      }
    }, headers: bearer(owner_token), as: :json
    assert_response :created
    trip_id = response.parsed_body.dig("data", "id")
    assert_equal User.find_by!(email: "owner@example.com").id, Trip.find(trip_id).user_id

    get "/api/v1/trips", headers: bearer(owner_token)
    assert_response :success
    assert_equal [ trip_id ], response.parsed_body.fetch("data").pluck("id")

    get "/api/v1/trips", headers: bearer(other_token)
    assert_response :success
    assert_empty response.parsed_body.fetch("data")

    get "/api/v1/trips/#{trip_id}", headers: bearer(other_token)
    assert_response :not_found

    patch "/api/v1/trips/#{trip_id}", params: {
      trip: { name: "Iași redenumit" }
    }, headers: bearer(owner_token), as: :json
    assert_response :success
    assert_equal "Iași redenumit", response.parsed_body.dig("data", "name")

    post "/api/v1/trips/#{trip_id}/replan", params: {
      trip: {
        starts_on: Date.current.iso8601,
        ends_on: Date.current.iso8601,
        party_size: 2,
        pace: "relaxed",
        transport_mode: "public_transport",
        max_distance_km: 20,
        preferences: {
          budget: "value", dietary: %w[vegan], interests: %w[nature]
        }
      }
    }, headers: bearer(owner_token), as: :json
    assert_response :success
    assert_equal trip_id, response.parsed_body.dig("data", "id")
    assert_equal 2, response.parsed_body.dig("data", "party_size")
    assert_equal "relaxed", response.parsed_body.dig("data", "pace")
    assert_equal "public_transport", response.parsed_body.dig("data", "transport_mode")
    assert_equal 20.0, response.parsed_body.dig("data", "max_distance_km")
    assert_equal "value", response.parsed_body.dig("data", "preferences", "budget")
    assert_equal %w[vegan], response.parsed_body.dig("data", "preferences", "dietary")
    assert_equal %w[nature], response.parsed_body.dig("data", "preferences", "interests")
    assert_equal 6, response.parsed_body.dig("data", "days", 0, "items").size
    assert @location.daily_forecasts.exists?(provider: "mock")

    post "/api/v1/trips/#{trip_id}/replan", params: {
      trip: { max_distance_km: 75 }
    }, headers: bearer(owner_token), as: :json
    assert_response :unprocessable_content
    assert_equal 20.0, Trip.find(trip_id).max_distance_km.to_f

    post "/api/v1/trips/#{trip_id}/replan",
      headers: bearer(other_token), as: :json
    assert_response :not_found
  end

  test "replaces one owned itinerary item without changing the rest of the trip" do
    owner_token = register("replace-owner@example.com")
    other_token = register("replace-other@example.com")
    owner = User.find_by!(email: "replace-owner@example.com")
    trip = Trip.create!(
      user: owner, location: @location, name: "Iași personal",
      starts_on: Date.current, ends_on: Date.current
    )
    day = trip.trip_days.create!(
      date: Date.current, daily_forecast: @forecast,
      weather_class: "clear", activity_context: "outdoor"
    )
    current = recommendation("Palatul Culturii", "api-current")
    alternative = recommendation("Muzeul Unirii", "api-alternative")
    item = day.itinerary_items.create!(
      recommendation: current, slot: "morning", kind: "activity",
      title: current.title, provider: current.provider,
      external_id: current.external_id, position: 1, starts_at: "10:00"
    )
    preserved = day.itinerary_items.create!(
      slot: "lunch", kind: "free_time", title: "Prânz liber", position: 2
    )

    post "/api/v1/trips/#{trip.id}/replace_item", params: {
      item_id: item.id, language: "ro"
    }, headers: bearer(owner_token), as: :json

    assert_response :success
    replacement = response.parsed_body.dig("data", "days", 0, "items").find do |entry|
      entry.fetch("id") == item.id
    end
    assert_equal alternative.title, replacement.fetch("title")
    assert_equal "10:00", replacement.fetch("starts_at")
    assert_equal "Prânz liber", preserved.reload.title

    post "/api/v1/trips/#{trip.id}/replace_item", params: {
      item_id: item.id
    }, headers: bearer(other_token), as: :json
    assert_response :not_found
  end

  private

  def register(email)
    post "/api/v1/auth/register", params: {
      email:,
      password: "weather-wise-2026",
      password_confirmation: "weather-wise-2026"
    }, as: :json
    assert_response :created
    response.parsed_body.dig("data", "access_token")
  end

  def bearer(token)
    { "Authorization" => "Bearer #{token}" }
  end

  def recommendation(title, external_id)
    Recommendation.create!(
      location: @location, recommendation_type: "activity", title:,
      summary: title, indoor: true, provider: "test", external_id:,
      weather_classes: %w[clear],
      metadata: { setting: "indoor", distance_km: 2.0 }
    )
  end
end
