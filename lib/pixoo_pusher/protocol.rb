# lib/pixoo_pusher/protocol.rb

require 'forwardable'
require 'pixoo_pusher/protocol/cloud_client'
require 'pixoo_pusher/protocol/local_client'

module PixooPusher
  # Unified interface for both cloud-backed and local device APIs.
  class Protocol
    extend Forwardable

    # @param cloud_transport [PixooPusher::Transport] pointing at app.divoom-gz.com
    # @param local_transport [PixooPusher::Transport] pointing at the device IP
    # @param device_id [String,Integer,nil] optional for local calls
    def initialize(cloud_transport:, local_transport:, device_id: nil)
      @cloud = Protocol::CloudClient.new(cloud_transport)
      @local = Protocol::LocalClient.new(local_transport, device_id: device_id)
    end

    #――――――――――――――――――――――――――――――――――――――
    # Cloud API methods
    #――――――――――――――――――――――――――――――――――――――
    def_delegators :@cloud,
      :discover_devices,
      :list_fonts,
      :list_dials,
      :list_dial_types,
      :list_galleries,
      :list_images

    #――――――――――――――――――――――――――――――――――――――
    # Local API methods
    #――――――――――――――――――――――――――――――――――――――
    def_delegators :@local,
      :execute_raw,
      :execute,
      :get_time,
      :set_time,
      :set_timezone,
      :set_geo,
      :play_buzzer,
      :get_all_settings,
      :screen_on,
      :screen_off,
      :set_brightness,
      :set_channel_index,
      :set_custom_page_index,
      :set_eq_position,
      :set_cloud_index,
      :get_channel_index,
      :set_clock_select_id,
      :get_clock_info,
      :play_builtin_gif,
      :send_http_gif,
      :get_next_gif_id,
      :reset_gif_id,
      :send_http_text,
      :clear_http_text,
      :send_remote,
      :send_http_item_list,
      :set_timer,
      :set_stopwatch,
      :set_scoreboard,
      :set_noise_status,
      :batch_command_list,
      :use_http_command_source,
      :upload_frame
  end
end
