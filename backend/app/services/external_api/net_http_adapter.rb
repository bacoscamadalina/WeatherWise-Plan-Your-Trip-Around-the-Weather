module ExternalApi
  class NetHttpAdapter
    def get(uri:, open_timeout:, read_timeout:, headers:)
      request = Net::HTTP::Get.new(uri, headers)
      perform(request, uri:, open_timeout:, read_timeout:)
    end

    def post(uri:, open_timeout:, read_timeout:, headers:, body:)
      request = Net::HTTP::Post.new(uri, headers)
      request.body = body
      perform(request, uri:, open_timeout:, read_timeout:)
    end

    private

    def perform(request, uri:, open_timeout:, read_timeout:)
      response = Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl: uri.scheme == "https",
        open_timeout:,
        read_timeout:
      ) { |http| http.request(request) }

      Response.new(status: response.code.to_i, body: response.body)
    end
  end
end
