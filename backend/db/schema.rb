# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_16_000011) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "access_tokens", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "token_digest", null: false
    t.string "name", default: "default", null: false
    t.datetime "last_used_at"
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_access_tokens_on_expires_at"
    t.index ["token_digest"], name: "index_access_tokens_on_token_digest", unique: true
    t.index ["user_id"], name: "index_access_tokens_on_user_id"
  end

  create_table "daily_forecasts", force: :cascade do |t|
    t.bigint "location_id", null: false
    t.date "forecast_date", null: false
    t.string "provider", null: false
    t.string "condition_code", null: false
    t.string "condition_label", null: false
    t.string "weather_class", null: false
    t.string "activity_context", null: false
    t.decimal "temperature_min_c", precision: 5, scale: 2, null: false
    t.decimal "temperature_max_c", precision: 5, scale: 2, null: false
    t.integer "precipitation_probability", default: 0, null: false
    t.decimal "precipitation_mm", precision: 7, scale: 2, default: "0.0", null: false
    t.decimal "wind_speed_kph", precision: 6, scale: 2, default: "0.0", null: false
    t.jsonb "raw_data", default: {}, null: false
    t.datetime "fetched_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "uv_index_max", precision: 5, scale: 2
    t.string "sunrise_local"
    t.string "sunset_local"
    t.integer "daylight_duration_seconds"
    t.index ["location_id", "forecast_date", "provider"], name: "index_daily_forecasts_on_location_date_provider", unique: true
    t.index ["location_id"], name: "index_daily_forecasts_on_location_id"
  end

  create_table "forecast_accesses", force: :cascade do |t|
    t.bigint "location_id", null: false
    t.date "accessed_on", null: false
    t.integer "request_count", default: 0, null: false
    t.datetime "last_accessed_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["last_accessed_at"], name: "index_forecast_accesses_on_last_accessed_at"
    t.index ["location_id", "accessed_on"], name: "index_forecast_accesses_on_location_id_and_accessed_on", unique: true
    t.index ["location_id"], name: "index_forecast_accesses_on_location_id"
  end

  create_table "hourly_forecasts", force: :cascade do |t|
    t.bigint "daily_forecast_id", null: false
    t.datetime "forecast_at", null: false
    t.string "provider", null: false
    t.string "condition_code", null: false
    t.string "condition_label", null: false
    t.string "weather_class", null: false
    t.string "activity_context", null: false
    t.decimal "temperature_c", precision: 5, scale: 2, null: false
    t.integer "precipitation_probability", default: 0, null: false
    t.decimal "precipitation_mm", precision: 7, scale: 2, default: "0.0", null: false
    t.decimal "wind_speed_kph", precision: 6, scale: 2, default: "0.0", null: false
    t.boolean "daylight", default: false, null: false
    t.jsonb "raw_data", default: {}, null: false
    t.datetime "fetched_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["daily_forecast_id", "forecast_at", "provider"], name: "index_hourly_forecasts_on_daily_time_provider", unique: true
    t.index ["daily_forecast_id"], name: "index_hourly_forecasts_on_daily_forecast_id"
  end

  create_table "itinerary_items", force: :cascade do |t|
    t.bigint "trip_day_id", null: false
    t.bigint "recommendation_id"
    t.string "slot", null: false
    t.string "kind", null: false
    t.string "title", null: false
    t.text "summary"
    t.string "venue_name"
    t.time "starts_at"
    t.time "ends_at"
    t.decimal "distance_km", precision: 6, scale: 1
    t.decimal "latitude", precision: 10, scale: 7
    t.decimal "longitude", precision: 10, scale: 7
    t.string "provider"
    t.string "external_id"
    t.string "url"
    t.string "image_url"
    t.decimal "rating", precision: 3, scale: 2
    t.integer "rating_count"
    t.integer "position", default: 0, null: false
    t.string "status", default: "suggested", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider", "external_id"], name: "index_itinerary_items_on_provider_and_external_id"
    t.index ["recommendation_id"], name: "index_itinerary_items_on_recommendation_id"
    t.index ["trip_day_id", "position"], name: "index_itinerary_items_on_trip_day_id_and_position"
    t.index ["trip_day_id"], name: "index_itinerary_items_on_trip_day_id"
  end

  create_table "locations", force: :cascade do |t|
    t.string "name", null: false
    t.string "country_code", limit: 2, null: false
    t.string "admin_area"
    t.decimal "latitude", precision: 10, scale: 7, null: false
    t.decimal "longitude", precision: 10, scale: 7, null: false
    t.string "timezone", default: "UTC", null: false
    t.string "provider", null: false
    t.string "external_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "country_name"
    t.string "feature_code"
    t.bigint "population"
    t.string "aliases", default: [], null: false, array: true
    t.jsonb "localized_names", default: {}, null: false
    t.string "hero_image_url"
    t.string "image_attribution"
    t.string "hero_image_source_url"
    t.string "hero_image_provider"
    t.datetime "hero_image_fetched_at"
    t.index ["aliases"], name: "index_locations_on_aliases", using: :gin
    t.index ["hero_image_fetched_at"], name: "index_locations_on_hero_image_fetched_at"
    t.index ["latitude", "longitude"], name: "index_locations_on_latitude_and_longitude"
    t.index ["localized_names"], name: "index_locations_on_localized_names", using: :gin
    t.index ["population"], name: "index_locations_on_population"
    t.index ["provider", "external_id"], name: "index_locations_on_provider_and_external_id", unique: true
  end

  create_table "recommendations", force: :cascade do |t|
    t.bigint "location_id"
    t.string "recommendation_type", null: false
    t.string "title", null: false
    t.text "summary", null: false
    t.string "venue_name"
    t.boolean "indoor", null: false
    t.string "provider", null: false
    t.string "external_id", null: false
    t.string "url"
    t.string "genres", default: [], null: false, array: true
    t.string "tags", default: [], null: false, array: true
    t.string "weather_classes", default: [], null: false, array: true
    t.jsonb "metadata", default: {}, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["genres"], name: "index_recommendations_on_genres", using: :gin
    t.index ["location_id"], name: "index_recommendations_on_location_id"
    t.index ["provider", "external_id"], name: "index_recommendations_on_provider_and_external_id", unique: true
    t.index ["recommendation_type"], name: "index_recommendations_on_recommendation_type"
    t.index ["weather_classes"], name: "index_recommendations_on_weather_classes", using: :gin
  end

  create_table "trip_days", force: :cascade do |t|
    t.bigint "trip_id", null: false
    t.bigint "daily_forecast_id"
    t.date "date", null: false
    t.string "weather_class"
    t.string "activity_context"
    t.string "summary"
    t.jsonb "weather_snapshot", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["daily_forecast_id"], name: "index_trip_days_on_daily_forecast_id"
    t.index ["trip_id", "date"], name: "index_trip_days_on_trip_id_and_date", unique: true
    t.index ["trip_id"], name: "index_trip_days_on_trip_id"
  end

  create_table "trips", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "location_id", null: false
    t.string "name", null: false
    t.date "starts_on", null: false
    t.date "ends_on", null: false
    t.integer "party_size", default: 1, null: false
    t.string "pace", default: "balanced", null: false
    t.string "transport_mode", default: "car", null: false
    t.decimal "max_distance_km", precision: 5, scale: 1, default: "50.0", null: false
    t.jsonb "preferences", default: {}, null: false
    t.string "status", default: "draft", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.time "arrival_time"
    t.time "departure_time"
    t.index ["location_id", "starts_on", "ends_on"], name: "index_trips_on_location_id_and_starts_on_and_ends_on"
    t.index ["location_id"], name: "index_trips_on_location_id"
    t.index ["user_id"], name: "index_trips_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "display_name"
    t.jsonb "preferences", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest", null: false
    t.index "lower((email)::text)", name: "index_users_on_lower_email", unique: true
  end

  add_foreign_key "access_tokens", "users"
  add_foreign_key "daily_forecasts", "locations"
  add_foreign_key "forecast_accesses", "locations"
  add_foreign_key "hourly_forecasts", "daily_forecasts"
  add_foreign_key "itinerary_items", "recommendations"
  add_foreign_key "itinerary_items", "trip_days"
  add_foreign_key "recommendations", "locations"
  add_foreign_key "trip_days", "daily_forecasts"
  add_foreign_key "trip_days", "trips"
  add_foreign_key "trips", "locations"
  add_foreign_key "trips", "users"
end
