require 'json'

module PixooPusher
  class Protocol
    # Client for Divoom local device APIs.
    # All commands POST to http://<device_ip>:80/post with a JSON body:
    # { "Command": "Namespace/Action", ... }
    class LocalClient
      POST_PATH = '/post'

      # @param transport [PixooPusher::Transport]
      # @param device_id [String,Integer,nil]
      def initialize(transport, device_id: nil)
        @transport = transport
        @device_id = device_id
      end

      # -- Generic executor ---------------------------------------------------

      # Execute any local command; returns parsed hash
      # @param command [String] command name
      # @param params  [Hash] additional parameters
      # @return [Hash] symbolized response
      def execute_raw(command:, **params)
        payload = command_payload(command, params)
        resp = @transport.post(POST_PATH, payload: payload)
        JSON.parse(resp.body, symbolize_names: true)
      rescue JSON::ParserError => e
        raise TransportError, "Local JSON parse error: #{e.message}"
      end

      # Execute a command and return true if error_code == 0
      # @param command [String]
      # @param params  [Hash]
      # @return [Boolean]
      def execute(command:, **params)
        execute_raw(command: command, **params).fetch(:error_code).zero?
      end

      # Internal payload builder
      private

      def command_payload(command, params)
        { Command: command, DeviceId: @device_id }.compact.merge(params)
      end

      public  # expose the following API methods

      # -- System / Device -----------------------------------------------------

      # Get device UTC timestamp
      # @return [Integer]
      def get_time
        execute_raw(command: 'Device/GetDeviceTime').fetch(:Utc)
      end

      # Set device UTC timestamp
      # @param utc [Integer]
      def set_time(utc:)
        execute(command: 'Device/SetUTC', Utc: utc)
      end

      # Set timezone string (e.g. "GMT-5")
      # @param time_zone_value [String]
      def set_timezone(time_zone_value:)
        execute(command: 'Sys/TimeZone', TimeZoneValue: time_zone_value)
      end

      # Set geographic location for weather
      # @param longitude [String, Numeric]
      # @param latitude  [String, Numeric]
      def set_geo(longitude:, latitude:)
        execute(command: 'Sys/LogAndLat', Longitude: longitude, Latitude: latitude)
      end

      # Play buzzer with timing parameters
      # @param active_time_in_cycle [Integer]
      # @param off_time_in_cycle    [Integer]
      # @param play_total_time      [Integer]
      def play_buzzer(active_time_in_cycle:, off_time_in_cycle:, play_total_time:)
        execute(command: 'Device/PlayBuzzer',
                ActiveTimeInCycle: active_time_in_cycle,
                OffTimeInCycle: off_time_in_cycle,
                PlayTotalTime: play_total_time)
      end

      # -- Channel Management --------------------------------------------------

      # Get all channel-related settings
      # @return [Hash]
      def get_all_settings
        execute_raw(command: 'Channel/GetAllConf')
      end

      # Turn screen on
      def screen_on
        execute(command: 'Channel/OnOffScreen', OnOff: 1)
      end

      # Turn screen off
      def screen_off
        execute(command: 'Channel/OnOffScreen', OnOff: 0)
      end

      # Set global LED brightness (0–100)
      # @param level [Integer]
      def set_brightness(level:)
        execute(command: 'Channel/SetBrightness', Brightness: level)
      end

      # Select channel index (0=Faces,1=Cloud,2=Visualizer,3=Custom,4=Blackout)
      # @param select_index [Integer]
      def set_channel_index(select_index:)
        execute(command: 'Channel/SetIndex', SelectIndex: select_index)
      end

      # Select custom sub-channel (0–2)
      # @param custom_page_index [Integer]
      def set_custom_page_index(custom_page_index:)
        execute(command: 'Channel/SetCustomPageIndex', CustomPageIndex: custom_page_index)
      end

      # Set visualizer preset position
      # @param eq_position [Integer]
      def set_eq_position(eq_position:)
        execute(command: 'Channel/SetEqPosition', EqPosition: eq_position)
      end

      # Set cloud sub-mode index (0–3)
      # @param index [Integer]
      def set_cloud_index(index:)
        execute(command: 'Channel/CloudIndex', Index: index)
      end

      # Get current channel index
      # @return [Integer]
      def get_channel_index
        execute_raw(command: 'Channel/GetIndex').fetch(:SelectIndex)
      end

      # -- Dial (Clock Face) ---------------------------------------------------

      # Select clock face by ID
      # @param clock_id [Integer]
      def set_clock_select_id(clock_id:)
        execute(command: 'Channel/SetClockSelectId', ClockId: clock_id)
      end

      # Get selected clock face info
      # @return [Hash]
      def get_clock_info
        execute_raw(command: 'Channel/GetClockInfo')
      end

      # -- Animation & GIFs ----------------------------------------------------

      # Play built-in GIF
      # @param file_type [Integer] 0=internal,1=uploaded
      # @param file_id   [String, nil]
      def play_builtin_gif(file_type: 0, file_id: nil)
        params = { FileType: file_type }
        params[:FileId] = file_id if file_id
        execute(command: 'Device/PlayTFGif', **params)
      end

      # Send multi-frame animation (Base64-encoded)
      def send_http_gif(pic_num:, pic_width:, pic_offset:, pic_id:, pic_speed:, pic_data:)
        execute(command: 'Draw/SendHttpGif',
                PicNum: pic_num,
                PicWidth: pic_width,
                PicOffset: pic_offset,
                PicID: pic_id,
                PicSpeed: pic_speed,
                PicData: pic_data)
      end

      # Get next available PicId
      # @return [Integer]
      def get_next_gif_id
        execute_raw(command: 'Draw/GetHttpGifId').fetch(:PicId)
      end

      # Reset GIF ID counter
      def reset_gif_id
        execute(command: 'Draw/ResetHttpGifId')
      end

      # Send text overlay
      def send_http_text(text_id:, x:, y:, dir:, font:, text_width:, speed:, text_string:, color:, align:)
        execute(command: 'Draw/SendHttpText',
                TextId: text_id,
                x: x, y: y,
                dir: dir,
                font: font,
                TextWidth: text_width,
                speed: speed,
                TextString: text_string,
                color: color,
                align: align)
      end

      # Clear text overlays
      def clear_http_text
        execute(command: 'Draw/ClearHttpText')
      end

      # Play remote & user images
      def send_remote(file_id:)
        execute(command: 'Draw/SendRemote', FileId: file_id)
      end

      # -- Display List (Smart Composite) -------------------------------------

      def send_http_item_list(item_list:)
        execute(command: 'Draw/SendHttpItemList', ItemList: item_list)
      end

      # -- Tools (Timers, Stopwatch, Scoreboard, Noise) ------------------------

      def set_timer(minute:, second:, status:)
        execute(command: 'Tools/SetTimer', Minute: minute, Second: second, Status: status)
      end

      def set_stopwatch(status:)
        execute(command: 'Tools/SetStopWatch', Status: status)
      end

      def set_scoreboard(blue_score:, red_score:)
        execute(command: 'Tools/SetScoreBoard', BlueScore: blue_score, RedScore: red_score)
      end

      def set_noise_status(noise_status:)
        execute(command: 'Tools/SetNoiseStatus', NoiseStatus: noise_status)
      end

      # -- Batch & External Scripts -------------------------------------------

      def batch_command_list(command_list:)
        execute(command: 'Draw/CommandList', CommandList: command_list)
      end

      def use_http_command_source(url:)
        execute(command: 'Draw/UseHTTPCommandSource', Url: url)
      end
    end
  end
end
