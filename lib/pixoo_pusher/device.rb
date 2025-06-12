require 'pixoo_pusher/transport'
require 'pixoo_pusher/protocol'
require 'pixoo_pusher/frame_buffer'

module PixooPusher
  # High-level Device API integrating cloud and local calls.
  # Instantiates transports and protocol, and delegates all Pixoo operations.
  class Device
    # @param host [String] local device IP address
    # @param device_id [String,Integer,nil] optional device identifier for local commands
    # @param cloud_host [String] cloud API host (default: 'app.divoom-gz.com')
    def initialize(host:, device_id: nil, cloud_host: 'app.divoom-gz.com')
      @local_transport = Transport.new(host: host, port: 80)
      @cloud_transport = Transport.new(host: cloud_host, port: 443, use_ssl: true)
      @protocol = Protocol.new(
        cloud_transport: @cloud_transport,
        local_transport: @local_transport,
        device_id:       device_id
      )
    end

    # Delegate undefined methods to the protocol layer
    def method_missing(name, *args, **kwargs, &block)
      if @protocol.respond_to?(name)
        @protocol.public_send(name, *args, **kwargs, &block)
      else
        super
      end
    end

    def respond_to_missing?(name, include_private = false)
      @protocol.respond_to?(name, include_private) || super
    end

    # Convenience for drawing a FrameBuffer to the device
    # @yield [FrameBuffer] yields a new 64x32 framebuffer
    # @return [Object] result of upload_frame
    def draw
      fb = FrameBuffer.new
      yield(fb)
      @protocol.upload_frame(fb)
    end
  end
end
