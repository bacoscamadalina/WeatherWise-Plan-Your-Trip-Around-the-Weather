require "test_helper"

class AuthApiTest < ActionDispatch::IntegrationTest
  test "registers, restores, and logs out a session without storing the raw token" do
    post "/api/v1/auth/register", params: {
      email: "Traveler@Example.com ",
      display_name: "Mara",
      password: "weather-wise-2026",
      password_confirmation: "weather-wise-2026"
    }, as: :json

    assert_response :created
    data = response.parsed_body.fetch("data")
    token = data.fetch("access_token")
    assert_equal "traveler@example.com", data.dig("user", "email")
    assert_equal "Mara", data.dig("user", "display_name")
    assert_nil data.dig("user", "password_digest")
    assert_not_equal token, AccessToken.last.token_digest
    assert_equal AccessToken.digest(token), AccessToken.last.token_digest

    get "/api/v1/auth/me", headers: bearer(token)
    assert_response :success
    assert_equal "traveler@example.com", response.parsed_body.dig("data", "email")

    delete "/api/v1/auth/logout", headers: bearer(token)
    assert_response :no_content

    get "/api/v1/auth/me", headers: bearer(token)
    assert_response :unauthorized
  end

  test "logs in with a normalized email and rejects a wrong password" do
    User.create!(
      email: "mara@example.com",
      password: "weather-wise-2026",
      password_confirmation: "weather-wise-2026"
    )

    post "/api/v1/auth/login", params: {
      email: " MARA@example.com ", password: "weather-wise-2026"
    }, as: :json
    assert_response :success
    assert response.parsed_body.dig("data", "access_token").present?

    post "/api/v1/auth/login", params: {
      email: "mara@example.com", password: "incorrect-password"
    }, as: :json
    assert_response :unauthorized
    assert_equal "invalid_credentials", response.parsed_body.dig("error", "code")
  end

  private

  def bearer(token)
    { "Authorization" => "Bearer #{token}" }
  end
end
