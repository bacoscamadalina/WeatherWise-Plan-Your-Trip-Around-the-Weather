require "test_helper"

class ExternalApi::HttpClientTest < ActiveSupport::TestCase
  class FakeAdapter
    attr_reader :calls, :last_request

    def initialize(*outcomes)
      @outcomes = outcomes
      @calls = 0
    end

    def get(**)
      respond_to_request
    end

    def post(**request)
      @last_request = request
      respond_to_request
    end

    private

    def respond_to_request
      @calls += 1
      outcome = @outcomes.shift
      raise outcome if outcome.is_a?(Exception)

      outcome
    end
  end

  class NoopSleeper
    def self.sleep(*) = nil
  end

  test "retries a temporary provider failure" do
    adapter = FakeAdapter.new(
      ExternalApi::Response.new(status: 503, body: "unavailable"),
      ExternalApi::Response.new(status: 200, body: '{"ok":true}')
    )
    client = ExternalApi::HttpClient.new(adapter:, sleeper: NoopSleeper)

    assert_equal({ "ok" => true }, client.get_json(URI("https://example.test")))
    assert_equal 2, adapter.calls
  end

  test "does not retry a client error" do
    adapter = FakeAdapter.new(ExternalApi::Response.new(status: 400, body: "bad request"))
    client = ExternalApi::HttpClient.new(adapter:, sleeper: NoopSleeper)

    error = assert_raises(ExternalApi::Error) { client.get_json(URI("https://example.test")) }
    assert_equal 400, error.status
    assert_equal 1, adapter.calls
  end

  test "wraps malformed json" do
    adapter = FakeAdapter.new(ExternalApi::Response.new(status: 200, body: "not-json"))
    client = ExternalApi::HttpClient.new(adapter:, sleeper: NoopSleeper)

    assert_raises(ExternalApi::Error) { client.get_json(URI("https://example.test")) }
  end

  test "wraps an exhausted network timeout in the provider error contract" do
    adapter = FakeAdapter.new(Timeout::Error.new, Timeout::Error.new, Timeout::Error.new)
    client = ExternalApi::HttpClient.new(adapter:, sleeper: NoopSleeper, max_attempts: 3)

    error = assert_raises(ExternalApi::Error) { client.get_json(URI("https://example.test")) }

    assert_match(/failed after 3 attempts/, error.message)
    assert_equal 3, adapter.calls
  end

  test "posts a json body with caller headers" do
    adapter = FakeAdapter.new(ExternalApi::Response.new(status: 200, body: '{"ok":true}'))
    client = ExternalApi::HttpClient.new(adapter:)

    result = client.post_json(
      URI("https://example.test/search"),
      body: { query: "museum" },
      headers: { "X-Test-Key" => "secret" }
    )

    assert_equal({ "ok" => true }, result)
    assert_equal '{"query":"museum"}', adapter.last_request[:body]
    assert_equal "secret", adapter.last_request.dig(:headers, "X-Test-Key")
  end
end
