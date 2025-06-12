require 'spec_helper'
require 'pixoo_pusher/device'

RSpec.describe PixooPusher::Device do
  subject { described_class.new(host: local_ip, device_id: device_id, cloud_host: cloud_host) }
  let(:local_ip)        { '192.168.0.42' }
  let(:device_id)       { 'DEV123' }
  let(:cloud_host)      { 'cloud.example.com' }
  let(:local_transport) { instance_double(PixooPusher::Transport) }
  let(:cloud_transport) { instance_double(PixooPusher::Transport) }
  let(:protocol)        { instance_double(PixooPusher::Protocol) }

  before do
    # Stub Transport.new for local and cloud
    allow(PixooPusher::Transport).to receive(:new) do |host:, port:, use_ssl: false|
      if host == local_ip && port == 80 && use_ssl == false
        local_transport
      elsif host == cloud_host && port == 443 && use_ssl == true
        cloud_transport
      else
        raise "Unexpected Transport.new args: #{host},#{port},#{use_ssl}"
      end
    end

    # Stub Protocol.new with the two transports
    allow(PixooPusher::Protocol).to receive(:new)
      .with(cloud_transport: cloud_transport,
            local_transport: local_transport,
            device_id:       device_id)
      .and_return(protocol)

    # Stub upload_frame so draw spec can run
    allow(protocol).to receive(:upload_frame)

    # Instantiate subject
    subject
  end

  describe '#initialize' do
    it 'instantiates local and cloud transports and protocol' do
      expect(PixooPusher::Transport).to have_received(:new)
        .with(host: local_ip, port: 80)
      expect(PixooPusher::Transport).to have_received(:new)
        .with(host: cloud_host, port: 443, use_ssl: true)
      expect(PixooPusher::Protocol).to have_received(:new)
        .with(cloud_transport: cloud_transport,
              local_transport: local_transport,
              device_id:       device_id)
    end
  end

  describe 'method delegation' do
    it 'forwards known methods to protocol' do
      allow(protocol).to receive(:set_brightness).with(level: 50).and_return(true)
      expect(subject.set_brightness(level: 50)).to be(true)
    end

    it 'responds to protocol methods' do
      # stub default respond_to? for any args
      allow(protocol).to receive(:respond_to?).with(any_args).and_return(false)
      # stub the specific protocol method
      allow(protocol).to receive(:respond_to?).with(:get_time, false).and_return(true)

      expect(subject.respond_to?(:get_time)).to be(true)
      expect(subject.respond_to?(:nonexistent)).to be(false)
    end

    it 'raises NoMethodError for unknown methods' do
      expect { subject.unknown_method }.to raise_error(NoMethodError)
    end
  end

  describe '#draw' do
    it 'yields a FrameBuffer and calls upload_frame on protocol' do
      result = subject.draw do |fb|
        expect(fb).to be_a(PixooPusher::FrameBuffer)
        fb.set_pixel(0, 0, 0xAAAFFF)
      end

      expect(protocol).to have_received(:upload_frame) do |fb|
        expect(fb.pixels.first).to eq(0xAAAFFF)
      end
      expect(result).to be_nil.or be(:ok)
    end
  end
end
