require 'json'

module PixooPusher
  class Protocol
    # Client for Divoom cloud-backed APIs (app.divoom-gz.com).
    # All calls are HTTPS POSTs with JSON in/out.
    class CloudClient
      # Initialize with a Transport instance configured for cloud host
      # @param transport [PixooPusher::Transport]
      def initialize(transport)
        @transport = transport
      end

      # Discover devices on the same LAN via cloud service
      # @return [Array<Hash>] list of devices
      def discover_devices
        resp = @transport.post('/Device/ReturnSameLANDevice', payload: {})
        parse_json(resp).fetch(:DeviceList)
      end

      # Fetch available time-dial font list
      # @param font_type [Integer]
      # @return [Array<Hash>] list of fonts
      def list_fonts(font_type:)
        resp = @transport.post(
          '/Device/GetTimeDialFontList',
          payload: { FontType: font_type }
        )
        parse_json(resp).fetch(:FontList)
      end

      # Fetch available dials (clock faces) by type and page
      # @param dial_type [String, Integer]
      # @param page [Integer]
      # @return [Hash] with keys :dials (array) and :total (integer)
      def list_dials(dial_type:, page: 1)
        resp = @transport.post(
          '/Channel/GetDialList',
          payload: { DialType: dial_type, Page: page }
        )
        body = parse_json(resp)
        { dials: body.fetch(:DialList), total: body.fetch(:TotalNum) }
      end

      # Fetch all dial types (categories)
      # @return [Array<String>]
      def list_dial_types
        resp = @transport.post('/Channel/GetDialType', payload: {})
        parse_json(resp).fetch(:DialTypeList)
      end

      # Fetch image galleries by type and page (e.g. backgrounds)
      # @param gallery_type [String, Integer]
      # @param page [Integer]
      # @return [Hash] with keys :galleries (array) and :total (integer)
      def list_galleries(gallery_type:, page: 1)
        resp = @transport.post(
          '/Channel/GetGalleryList',
          payload: { GalleryType: gallery_type, Page: page }
        )
        body = parse_json(resp)
        { galleries: body.fetch(:GalleryList), total: body.fetch(:TotalNum) }
      end

      # Fetch images within a gallery by ID and page
      # @param gallery_id [String, Integer]
      # @param page [Integer]
      # @return [Hash] with keys :images (array) and :total (integer)
      def list_images(gallery_id:, page: 1)
        resp = @transport.post(
          '/Channel/GetImageList',
          payload: { GalleryId: gallery_id, Page: page }
        )
        body = parse_json(resp)
        { images: body.fetch(:ImageList), total: body.fetch(:TotalNum) }
      end

      private

      # Parse response body JSON into symbolized hash
      # @param resp [Faraday::Response]
      # @return [Hash]
      def parse_json(resp)
        JSON.parse(resp.body, symbolize_names: true)
      rescue JSON::ParserError => e
        raise TransportError, "Cloud JSON parse error: #{e.message}"
      end
    end
  end
end
