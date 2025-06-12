require 'spec_helper'
require 'faraday'
require 'pixoo_pusher/transport'
require 'json'

RSpec.describe PixooPusher::Transport do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }

  let(:test_connection) do
    Faraday.new do |builder|
      builder.adapter :test, stubs
    end
  end

  subject(:transport) do
    described_class.new(
      host:       'device.local',
      port:       9999,
      timeout:    2,
      use_ssl:    true,
      connection: test_connection
    )
  end

  describe '#initialize' do
    it 'rejects an empty host' do
      expect { described_class.new(host: '') }
        .to raise_error(ArgumentError, /host must be a non-empty String/)
    end

    it 'honors an injected connection' do
      expect(transport.instance_variable_get(:@connection)).to equal(test_connection)
    end
  end

  describe '#get' do
    it 'returns raw JSON string on 200' do
      stubs.get('/status?foo=bar') { [200, { 'Content-Type' => 'application/json' }, { ok: true }.to_json] }

      resp = transport.get('/status', params: { foo: 'bar' })
      expect(resp.status).to eq(200)
      parsed = JSON.parse(resp.body, symbolize_names: true)
      expect(parsed).to eq(ok: true)
    end

    it 'passes through 4xx/5xx without raising' do
      stubs.get('/not_found') { [404, { 'Content-Type' => 'application/json' }, { error: 'Missing' }.to_json] }

      resp = transport.get('/not_found')
      expect(resp.status).to eq(404)
      parsed = JSON.parse(resp.body, symbolize_names: true)
      expect(parsed).to eq(error: 'Missing')
    end

    it 'wraps network failures in TransportError' do
      allow(test_connection).to receive(:get)
        .and_raise(Faraday::ConnectionFailed.new('conn error'))

      expect { transport.get('/anything') }
        .to raise_error(PixooPusher::TransportError, /Network error/)
    end

    it 'wraps timeouts in TransportError' do
      allow(test_connection).to receive(:get)
        .and_raise(Faraday::TimeoutError.new('timeout'))

      expect { transport.get('/timeout') }
        .to raise_error(PixooPusher::TransportError, /Network error/)
    end

    it 'wraps JSON parse errors in TransportError' do
      stubs.get('/bad_json') { [200, { 'Content-Type' => 'application/json' }, 'nope'] }

      expect { transport.get('/bad_json') }
        .to raise_error(PixooPusher::TransportError, /Invalid JSON/)
    end
  end

  describe '#post' do
    it 'sends a JSON payload and parses the response string' do
      stubs.post('/upload') do |env|
        # ensure payload is JSON-encoded
        parsed_request = JSON.parse(env.body, symbolize_names: true)
        expect(parsed_request).to eq(data: '123')

        [201, { 'Content-Type' => 'application/json' }, { success: true }.to_json]
      end

      resp = transport.post('/upload', payload: { data: '123' })
      expect(resp.status).to eq(201)

      parsed = JSON.parse(resp.body, symbolize_names: true)
      expect(parsed).to eq(success: true)
    end

    it 'wraps connection failures in TransportError' do
      allow(test_connection).to receive(:post)
        .and_raise(Faraday::ConnectionFailed.new('oops'))

      expect {
        transport.post('/upload', payload: {})
      }.to raise_error(PixooPusher::TransportError, /Network error/)
    end
  end
end
