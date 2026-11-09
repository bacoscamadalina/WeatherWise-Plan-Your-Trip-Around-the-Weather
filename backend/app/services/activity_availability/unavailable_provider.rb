module ActivityAvailability
  class UnavailableProvider < Provider
    def name = "unavailable"

    def check(recommendation:, forecast:, period:)
      Result.new(
        status: "not_configured",
        label: "Live hours are not available",
        detail: "Use the listed hours and confirm with the venue before visiting.",
        period:,
        provider: nil,
        checked_at: nil,
        place_name: recommendation.venue_name.presence || recommendation.title,
        place_url: recommendation.url
      )
    end
  end
end
