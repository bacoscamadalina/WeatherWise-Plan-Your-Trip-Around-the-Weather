module Api
  module V1
    class BaseController < ApplicationController
      rescue_from ActiveRecord::RecordNotFound do
        render json: { error: { code: "not_found", message: "Resource not found" } }, status: :not_found
      end

      rescue_from ActionController::BadRequest do |error|
        render json: { error: { code: "bad_request", message: error.message } }, status: :bad_request
      end

      rescue_from ActiveRecord::RecordInvalid do |error|
        render json: {
          error: { code: "validation_failed", message: error.record.errors.full_messages.to_sentence }
        }, status: :unprocessable_content
      end

      rescue_from ExternalApi::Error do |error|
        Rails.logger.warn("External provider failure: #{error.message}")
        render json: {
          error: { code: "provider_unavailable", message: "Provider data is temporarily unavailable" }
        }, status: :bad_gateway
      end

      private

      def current_user
        return @current_user if defined?(@current_user)

        raw_token = bearer_token
        return @current_user = nil if raw_token.blank?

        @current_access_token = AccessToken.active.includes(:user).find_by(
          token_digest: AccessToken.digest(raw_token)
        )
        @current_user = @current_access_token&.user
      end

      def authenticate_user!
        return if current_user

        render json: {
          error: { code: "unauthorized", message: "A valid session is required" }
        }, status: :unauthorized
      end

      def bearer_token
        scheme, token = request.authorization.to_s.split(" ", 2)
        scheme&.casecmp?("Bearer") ? token : nil
      end

      def user_json(user)
        {
          id: user.id,
          email: user.email,
          display_name: user.display_name,
          preferences: user.preferences
        }
      end

      def location_json(location)
        {
          id: location.id,
          name: location.name,
          display_name: location.display_name,
          country_code: location.country_code,
          country_name: location.country_name,
          admin_area: location.admin_area,
          latitude: location.latitude.to_f,
          longitude: location.longitude.to_f,
          timezone: location.timezone,
          feature_code: location.feature_code,
          population: location.population,
          localized_names: location.localized_names,
          hero_image_url: location.hero_image_url,
          image_attribution: location.image_attribution,
          hero_image_source_url: location.hero_image_source_url,
          hero_image_provider: location.hero_image_provider
        }
      end

      def requested_language
        requested = params[:language].presence || request.headers["Accept-Language"].to_s.split(",").first
        value = requested.to_s.downcase.split("-").first.presence
        value&.match?(/\A[a-z]{2,3}\z/) ? value : "en"
      end

      def forecast_json(forecast)
        {
          id: forecast.id,
          date: forecast.forecast_date.iso8601,
          condition: {
            code: forecast.condition_code,
            label: forecast.condition_label,
            weather_class: forecast.weather_class
          },
          activity_context: forecast.activity_context,
          temperature: {
            min_c: forecast.temperature_min_c.to_f,
            max_c: forecast.temperature_max_c.to_f
          },
          precipitation: {
            probability: forecast.precipitation_probability,
            amount_mm: forecast.precipitation_mm.to_f
          },
          wind_speed_kph: forecast.wind_speed_kph.to_f,
          uv_index_max: forecast.uv_index_max&.to_f,
          daylight: {
            sunrise_local: forecast.sunrise_local,
            sunset_local: forecast.sunset_local,
            duration_seconds: forecast.daylight_duration_seconds
          },
          current: current_conditions_json(forecast),
          advisories: Weather::AdvisoryClassifier.new.call(forecast).map(&:to_h)
        }
      end

      def current_conditions_json(forecast)
        current = forecast.raw_data.deep_symbolize_keys[:current]
        return if current.blank?

        classification = Weather::Classifier.new.call(
          code: current.fetch(:weather_code),
          temperature_max_c: current.fetch(:temperature_c),
          precipitation_probability: forecast.precipitation_probability
        )
        {
          observed_at: current.fetch(:time),
          condition: {
            code: current.fetch(:weather_code).to_s,
            label: classification.condition_label,
            weather_class: classification.weather_class
          },
          temperature_c: current.fetch(:temperature_c).to_f,
          apparent_temperature_c: current.fetch(:apparent_temperature_c).to_f,
          precipitation_mm: current.fetch(:precipitation_mm, 0).to_f,
          wind_speed_kph: current.fetch(:wind_speed_kph, 0).to_f,
          daylight: current.fetch(:daylight, false)
        }
      end
    end
  end
end
