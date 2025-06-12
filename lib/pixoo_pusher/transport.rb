require 'faraday'
require 'json'
require 'uri'

module PixooPusher
  # Raised for any network, timeout, or JSON parsing errors
  class TransportError < StandardError; end

  # Low-level, flexible HTTP transport for Divoom Pixoo devices.
  # Supports JSON, form-encoded, multipart, and raw requests.
  class Transport
    DEFAULT_PORT    = 8181
    DEFAULT_TIMEOUT = 5

    # @param host [String] device IP or hostname (required)
    # @param port [Integer]
    # @param timeout [Numeric]
    # @param use_ssl [Boolean]
    # @param connection [Faraday::Connection] for dependency injection (testing)
    def initialize(host:, port: DEFAULT_PORT, timeout: DEFAULT_TIMEOUT, use_ssl: false, connection: nil)
      @host       = validate_host!(host)
      @port       = port
      @timeout    = timeout
      @scheme     = use_ssl ? 'https' : 'http'
      @connection = connection || build_connection
    end

    # Perform a GET request.
    # @param path [String] endpoint path (e.g. '/v1/info')
    # @param params [Hash] query parameters
    # @param headers [Hash] additional headers
    # @param parse_json [Boolean] whether to auto-parse JSON responses
    # @return [Faraday::Response]
    # @raise [TransportError]
    def get(path, params: {}, headers: {}, parse_json: true)
      resp = perform_request(:get, path, params: params, headers: headers)
      parse_json?(resp) if parse_json
      resp
    end

    # Perform a POST request.
    # @param path [String]
    # @param payload [Object] body to send (Hash,String,IO,Faraday::Multipart::FilePart)
    # @param headers [Hash] e.g. {'Content-Type'=>'application/json'}
    # @param parse_json [Boolean]
    # @return [Faraday::Response]
    def post(path, payload: nil, headers: {}, parse_json: true)
      # Default to JSON content-type for Hash payloads
      if payload.is_a?(Hash)
        headers = { 'Content-Type' => 'application/json' }.merge(headers)
      end

      resp = perform_request(:post, path, body: payload, headers: headers)
      parse_json?(resp) if parse_json
      resp
    end

    private

    attr_reader :host, :port, :timeout, :scheme, :connection

    def build_connection
      Faraday.new(url: "#{scheme}://#{host}:#{port}") do |f|
        f.options.timeout      = timeout
        f.options.open_timeout = timeout
        f.adapter Faraday.default_adapter
      end
    end

    def perform_request(method, path, params: {}, body: nil, headers: {})
      connection.send(method, path) do |req|
        req.params.update(params) if params.any?
        req.headers.update(headers) if headers.any?
        req.body = encode_body(req.headers['Content-Type'], body) if body
      end
    rescue Faraday::ConnectionFailed, Faraday::TimeoutError => e
      raise TransportError, "Network error on #{method.upcase} #{path}: #{e.message}"
    end

    # Encode body based on Content-Type
    def encode_body(content_type, body)
      case content_type.to_s
      when %r{application/json}
        JSON.generate(body)
      when %r{application/x-www-form-urlencoded}
        URI.encode_www_form(body)
      else
        body
      end
    end

    # Automatically parse JSON responses if header indicates JSON
    def parse_json?(resp)
      ct = resp.headers['Content-Type'].to_s
      return unless ct.include?('application/json')

      begin
        JSON.parse(resp.body)
      rescue JSON::ParserError => e
        raise TransportError, "Invalid JSON on #{resp.env.method.upcase} #{resp.env.url.path}: #{e.message}"
      end
    end

    # Validate that host is a non-empty String
    def validate_host!(host)
      unless host.is_a?(String) && !host.strip.empty?
        raise ArgumentError, 'host must be a non-empty String'
      end
      host
    end
  end
end
