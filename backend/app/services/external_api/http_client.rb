require "net/http"
require "json"

module ExternalApi
  class HttpClient
    RETRIABLE_STATUSES = [ 408, 429, 500, 502, 503, 504 ].freeze
    RETRIABLE_ERRORS = [ Timeout::Error, Errno::ECONNRESET, Errno::ECONNREFUSED, SocketError ].freeze

    def initialize(adapter: NetHttpAdapter.new, open_timeout: 3, read_timeout: 8, max_attempts: 3, sleeper: Kernel)
      @adapter = adapter
      @open_timeout = open_timeout
      @read_timeout = read_timeout
      @max_attempts = max_attempts
      @sleeper = sleeper
    end

    def get_json(uri, headers: {})
      request_json(:get, uri, headers:)
    end

    def post_json(uri, body:, headers: {})
      request_json(:post, uri, headers:, body: JSON.generate(body))
    end

    private

    def request_json(method, uri, headers:, body: nil)
      attempts = 0

      begin
        attempts += 1
        request_headers = {
          "Accept" => "application/json",
          "User-Agent" => "WeatherWise/0.1 (contact: #{ENV.fetch("PROVIDER_CONTACT", "not-configured")})"
        }.merge(headers)
        response = @adapter.public_send(
          method,
          uri:,
          open_timeout: @open_timeout,
          read_timeout: @read_timeout,
          headers: request_headers,
          **(body ? { body: } : {})
        )
        raise Error.new("Provider returned HTTP #{response.status}", status: response.status) unless response.status.between?(200, 299)

        JSON.parse(response.body)
      rescue *RETRIABLE_ERRORS => error
        if attempts < @max_attempts
          @sleeper.sleep(0.2 * attempts)
          retry
        end

        raise Error, "Provider request failed after #{attempts} attempts: #{error.class}"
      rescue Error => error
        raise unless retryable?(error) && attempts < @max_attempts

        @sleeper.sleep(0.2 * attempts)
        retry
      rescue JSON::ParserError => error
        raise Error, "Provider returned invalid JSON: #{error.message}"
      end
    end

    def retryable?(error)
      !error.is_a?(Error) || RETRIABLE_STATUSES.include?(error.status)
    end
  end
end
