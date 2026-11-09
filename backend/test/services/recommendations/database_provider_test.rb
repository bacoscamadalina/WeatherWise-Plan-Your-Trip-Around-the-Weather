require "test_helper"

class Recommendations::DatabaseProviderTest < ActiveSupport::TestCase
  test "returns Wikipedia places only in the requested interface language" do
    location = Location.create!(
      name: "Iași", country_code: "RO", latitude: 47.1585, longitude: 27.6014,
      timezone: "Europe/Bucharest", provider: "test", external_id: "iasi-language-filter"
    )
    romanian = create_wikipedia_recommendation(location:, external_id: "ro-place", language: "ro")
    create_wikipedia_recommendation(location:, external_id: "en-place", language: "en")
    create_wikipedia_recommendation(location:, external_id: "legacy-place", language: nil)
    request = Recommendations::Request.new(
      location:,
      forecast: nil,
      preferences: { language: "ro" }
    )

    results = Recommendations::DatabaseProvider.new.suggestions(request:)

    assert_includes results, romanian
    assert_equal [ "ro" ], results.filter_map { |item| item.metadata["language"] if item.provider == "wikipedia" }.uniq
    assert_not results.any? { |item| item.external_id.in?(%w[en-place legacy-place]) }
  end

  test "uses localized TMDB movies instead of seeded movie demos when live results exist" do
    location = Location.create!(
      name: "Iași", country_code: "RO", latitude: 47.1585, longitude: 27.6014,
      timezone: "Europe/Bucharest", provider: "test", external_id: "iasi-movie-language-filter"
    )
    live = create_movie(provider: "tmdb", external_id: "ro-42", language: "ro")
    create_movie(provider: "tmdb", external_id: "en-42", language: "en")
    create_movie(provider: "seed", external_id: "movie-demo", language: nil)
    request = Recommendations::Request.new(location:, forecast: nil, preferences: { language: "ro" })

    results = Recommendations::DatabaseProvider.new.suggestions(request:)

    assert_includes results, live
    assert_not results.any? { |item| item.external_id.in?(%w[en-42 movie-demo]) }
  end

  test "does not mix OpenStreetMap activity copy between interface languages" do
    location = Location.create!(
      name: "Bicaz", country_code: "RO", latitude: 46.9167, longitude: 26.0667,
      timezone: "Europe/Bucharest", provider: "test", external_id: "bicaz-osm-language-filter"
    )
    romanian = create_activity(
      location:, provider: "openstreetmap", external_id: "ro:peak", language: "ro"
    )
    create_activity(location:, provider: "openstreetmap", external_id: "en:peak", language: "en")
    request = Recommendations::Request.new(location:, forecast: nil, preferences: { language: "ro" })

    results = Recommendations::DatabaseProvider.new.suggestions(request:)

    assert_includes results, romanian
    assert_not results.any? { |item| item.external_id == "en:peak" }
  end

  private

  def create_wikipedia_recommendation(location:, external_id:, language:)
    create_activity(location:, provider: "wikipedia", external_id:, language:)
  end

  def create_activity(location:, provider:, external_id:, language:)
    Recommendation.create!(
      location:,
      recommendation_type: "activity",
      title: external_id,
      summary: "Place",
      indoor: true,
      provider:,
      external_id:,
      metadata: language ? { language: } : {}
    )
  end

  def create_movie(provider:, external_id:, language:)
    Recommendation.create!(
      recommendation_type: "movie",
      title: external_id,
      summary: "Movie",
      indoor: true,
      provider:,
      external_id:,
      metadata: language ? { language: } : {}
    )
  end
end
