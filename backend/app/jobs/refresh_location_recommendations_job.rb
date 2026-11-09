class RefreshLocationRecommendationsJob < ApplicationJob
  queue_as :recommendations

  discard_on ActiveJob::DeserializationError
  retry_on ExternalApi::Error, wait: :polynomially_longer, attempts: 3

  def perform(location:, forecast:, type: nil, language: "en")
    request = Recommendations::Request.new(
      location:,
      forecast:,
      preferences: { type:, language: }
    )
    provider.suggestions(request:)
  end

  private

  def provider
    Recommendations::RefreshingProvider.new
  end
end
