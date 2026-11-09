module Api
  module V1
    class AuthController < BaseController
      before_action :authenticate_user!, only: %i[me logout]

      def register
        user = User.create!(registration_params)
        render_session(user, status: :created)
      end

      def login
        user = User.find_by(email: normalized_email)
        unless user&.authenticate(params[:password].to_s)
          return render json: {
            error: { code: "invalid_credentials", message: "Email or password is incorrect" }
          }, status: :unauthorized
        end

        render_session(user)
      end

      def me
        render json: { data: user_json(current_user) }
      end

      def logout
        @current_access_token&.destroy!
        head :no_content
      end

      private

      def registration_params
        params.permit(:email, :display_name, :password, :password_confirmation)
      end

      def normalized_email
        params[:email].to_s.strip.downcase
      end

      def render_session(user, status: :ok)
        token, raw_token = AccessToken.issue_for(
          user,
          name: request.user_agent.to_s.first(120).presence || "WeatherWise client"
        )
        render json: {
          data: {
            user: user_json(user),
            access_token: raw_token,
            expires_at: token.expires_at.iso8601
          }
        }, status:
      end
    end
  end
end
