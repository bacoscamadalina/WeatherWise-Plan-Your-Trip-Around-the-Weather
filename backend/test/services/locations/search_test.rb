require "test_helper"

class Locations::SearchTest < ActiveSupport::TestCase
  class ListProvider < Geocoding::Provider
    attr_reader :last_limit, :last_language

    def initialize(results)
      @results = results
    end

    def search(query:, limit:, language: nil)
      @last_limit = limit
      @last_language = language
      @results.first(limit)
    end
  end

  test "finds and persists Iasi without diacritics" do
    results = Locations::Search.new(provider: Geocoding::MockProvider.new).call(query: "Iasi")

    assert_equal 1, results.size
    assert_equal "Iași", results.first.name
    assert_predicate results.first, :persisted?
  end

  test "finds a location through a known alias" do
    results = Locations::Search.new(provider: Geocoding::MockProvider.new).call(query: "Jassy")

    assert_equal "Iași", results.first.name
    assert_includes results.first.aliases, "Jassy"
  end

  test "ranks exact names before larger prefix matches" do
    provider = ListProvider.new([
      result(id: "2", name: "Parisville", population: 2_000_000),
      result(id: "1", name: "Paris", population: 100_000, feature_code: "PPLC")
    ])

    page = Locations::Search.new(provider:).call(query: "Paris", per_page: 2)

    assert_equal %w[Paris Parisville], page.map(&:name)
  end

  test "paginates provider results and reports a following page" do
    provider = ListProvider.new(
      12.times.map { |index| result(id: index.to_s, name: "Test #{index}", population: 12 - index) }
    )

    page = Locations::Search.new(provider:).call(
      query: "Test",
      page: 2,
      per_page: 5,
      language: "ro"
    )

    assert_equal 2, page.page
    assert_equal 5, page.size
    assert page.has_more
    assert_equal 11, provider.last_limit
    assert_equal "ro", provider.last_language
  end

  test "retains localized names as aliases across searches" do
    english = ListProvider.new([ result(id: "same", name: "Iasi") ])
    romanian = ListProvider.new([ result(id: "same", name: "Iași") ])

    Locations::Search.new(provider: english).call(query: "Iasi", language: "en")
    location = Locations::Search.new(provider: romanian).call(query: "Iași", language: "ro").first

    assert_equal({ "en" => "Iasi", "ro" => "Iași" }, location.localized_names)
    assert_includes location.aliases, "Iasi"
  end

  private

  def result(id:, name:, population: 10_000, feature_code: "PPL")
    Geocoding::Result.new(
      name:,
      country_code: "RO",
      admin_area: "Test County",
      latitude: 47.0,
      longitude: 27.0,
      timezone: "Europe/Bucharest",
      provider: "list",
      external_id: id,
      country_name: "Romania",
      feature_code:,
      population:,
      aliases: []
    )
  end
end
