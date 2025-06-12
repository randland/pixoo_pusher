require 'spec_helper'
require 'pixoo_pusher/protocol/local_client'
require 'json'

RSpec.describe PixooPusher::Protocol::LocalClient do
  let(:transport) { instance_double(PixooPusher::Transport) }
  subject(:client) { described_class.new(transport, device_id: 'DEV123') }

  # Helper to stub a transport.post response
  def stub_post(expected_payload, response_body)
    response = double('Response', body: response_body.to_json)
    expect(transport).to receive(:post)
      .with('/post', payload: expected_payload)
      .and_return(response)
  end

  context 'generic execution' do
    it 'execute_raw returns parsed hash' do
      payload = { Command: 'Foo/Bar', DeviceId: 'DEV123', Baz: 1 }
      expected = { error_code: 0, data: 42 }
      stub_post(payload, expected)
      result = client.execute_raw(command: 'Foo/Bar', Baz: 1)
      expect(result).to eq(expected)
    end

    it 'execute returns true on error_code 0' do
      payload = { Command: 'X/Y', DeviceId: 'DEV123' }
      stub_post(payload, error_code: 0)
      expect(client.execute(command: 'X/Y')).to be(true)
    end

    it 'execute returns false on non-zero error_code' do
      payload = { Command: 'X/Y', DeviceId: 'DEV123' }
      stub_post(payload, error_code: 5)
      expect(client.execute(command: 'X/Y')).to be(false)
    end

    it 'raises TransportError on invalid JSON in execute_raw' do
      payload = { Command: 'Bad/Json', DeviceId: 'DEV123' }
      expect(transport).to receive(:post)
        .with('/post', payload: payload)
        .and_return(double('Response', body: 'not json'))
      expect { client.execute_raw(command: 'Bad/Json') }
        .to raise_error(PixooPusher::TransportError, /Local JSON parse error/)
    end
  end

  context 'system commands' do
    it '#get_time returns Utc' do
      expected = { error_code: 0, Utc: 999 }
      stub_post({ Command: 'Device/GetDeviceTime', DeviceId: 'DEV123' }, expected)
      expect(client.get_time).to eq(999)
    end

    it '#set_time sets UTC' do
      stub_post({ Command: 'Device/SetUTC', DeviceId: 'DEV123', Utc: 1_600_000_000 }, error_code: 0)
      expect(client.set_time(utc: 1_600_000_000)).to be(true)
    end

    it '#set_timezone sets timezone' do
      stub_post({ Command: 'Sys/TimeZone', DeviceId: 'DEV123', TimeZoneValue: 'GMT-5' }, error_code: 0)
      expect(client.set_timezone(time_zone_value: 'GMT-5')).to be(true)
    end

    it '#set_geo sends longitude and latitude' do
      stub_post({ Command: 'Sys/LogAndLat', DeviceId: 'DEV123', Longitude: '10', Latitude: '20' }, error_code: 0)
      expect(client.set_geo(longitude: '10', latitude: '20')).to be(true)
    end

    it '#play_buzzer sends buzzer params' do
      stub_post({ Command: 'Device/PlayBuzzer', DeviceId: 'DEV123', ActiveTimeInCycle: 1, OffTimeInCycle: 2, PlayTotalTime: 3 }, error_code: 0)
      expect(client.play_buzzer(active_time_in_cycle: 1, off_time_in_cycle: 2, play_total_time: 3)).to be(true)
    end
  end

  context 'channel management' do
    it '#get_all_settings returns hash' do
      expected = { error_code: 0, foo: 'bar' }
      stub_post({ Command: 'Channel/GetAllConf', DeviceId: 'DEV123' }, expected)
      expect(client.get_all_settings).to eq(expected)
    end

    it '#screen_on and #screen_off' do
      stub_post({ Command: 'Channel/OnOffScreen', DeviceId: 'DEV123', OnOff: 1 }, error_code: 0)
      expect(client.screen_on).to be(true)
      stub_post({ Command: 'Channel/OnOffScreen', DeviceId: 'DEV123', OnOff: 0 }, error_code: 0)
      expect(client.screen_off).to be(true)
    end

    it '#set_brightness posts correct payload' do
      stub_post({ Command: 'Channel/SetBrightness', DeviceId: 'DEV123', Brightness: 80 }, error_code: 0)
      expect(client.set_brightness(level: 80)).to be(true)
    end

    it 'channel index methods' do
      stub_post({ Command: 'Channel/SetIndex', DeviceId: 'DEV123', SelectIndex: 2 }, error_code: 0)
      expect(client.set_channel_index(select_index: 2)).to be(true)
      stub_post({ Command: 'Channel/GetIndex', DeviceId: 'DEV123' }, error_code: 0, SelectIndex: 3)
      expect(client.get_channel_index).to eq(3)
    end

    it 'custom page, eq position, and cloud index' do
      stub_post({ Command: 'Channel/SetCustomPageIndex', DeviceId: 'DEV123', CustomPageIndex: 1 }, error_code: 0)
      expect(client.set_custom_page_index(custom_page_index: 1)).to be(true)
      stub_post({ Command: 'Channel/SetEqPosition', DeviceId: 'DEV123', EqPosition: 4 }, error_code: 0)
      expect(client.set_eq_position(eq_position: 4)).to be(true)
      stub_post({ Command: 'Channel/CloudIndex', DeviceId: 'DEV123', Index: 0 }, error_code: 0)
      expect(client.set_cloud_index(index: 0)).to be(true)
    end
  end

  context 'dial (clock face)' do
    it '#set_clock_select_id posts correct payload' do
      stub_post({ Command: 'Channel/SetClockSelectId', DeviceId: 'DEV123', ClockId: 12 }, error_code: 0)
      expect(client.set_clock_select_id(clock_id: 12)).to be(true)
    end

    it '#get_clock_info returns hash' do
      expected = { error_code: 0, ClockId: 5, Brightness: 90 }
      stub_post({ Command: 'Channel/GetClockInfo', DeviceId: 'DEV123' }, expected)
      expect(client.get_clock_info).to eq(expected)
    end
  end

  context 'animation & GIFs' do
    it '#play_builtin_gif with and without file_id' do
      stub_post({ Command: 'Device/PlayTFGif', DeviceId: 'DEV123', FileType: 0 }, error_code: 0)
      expect(client.play_builtin_gif).to be(true)
      stub_post({ Command: 'Device/PlayTFGif', DeviceId: 'DEV123', FileType: 1, FileId: 'X' }, error_code: 0)
      expect(client.play_builtin_gif(file_type: 1, file_id: 'X')).to be(true)
    end

    it '#send_http_gif sends all params' do
      payload = { Command: 'Draw/SendHttpGif', DeviceId: 'DEV123', PicNum: 2, PicWidth: 4, PicOffset: 0, PicID: 1, PicSpeed: 5, PicData: 'ABC' }
      stub_post(payload, error_code: 0)
      expect(client.send_http_gif(pic_num: 2, pic_width: 4, pic_offset: 0, pic_id: 1, pic_speed: 5, pic_data: 'ABC')).to be(true)
    end

    it '#get_next_gif_id and #reset_gif_id' do
      stub_post({ Command: 'Draw/GetHttpGifId', DeviceId: 'DEV123' }, error_code: 0, PicId: 7)
      expect(client.get_next_gif_id).to eq(7)
      stub_post({ Command: 'Draw/ResetHttpGifId', DeviceId: 'DEV123' }, error_code: 0)
      expect(client.reset_gif_id).to be(true)
    end

    it '#send_http_text and #clear_http_text' do
      text_params = { Command: 'Draw/SendHttpText', DeviceId: 'DEV123', TextId: 1, x: 0, y: 0, dir: 0, font: 1, TextWidth: 10, speed: 2, TextString: 'Hi', color: 0, align: 0 }
      stub_post(text_params, error_code: 0)
      expect(client.send_http_text(text_id: 1, x: 0, y: 0, dir: 0, font: 1, text_width: 10, speed: 2, text_string: 'Hi', color: 0, align: 0)).to be(true)
      stub_post({ Command: 'Draw/ClearHttpText', DeviceId: 'DEV123' }, error_code: 0)
      expect(client.clear_http_text).to be(true)
    end

    it '#send_remote sends FileId' do
      stub_post({ Command: 'Draw/SendRemote', DeviceId: 'DEV123', FileId: 'XYZ' }, error_code: 0)
      expect(client.send_remote(file_id: 'XYZ')).to be(true)
    end
  end

  context 'display-list' do
    it '#send_http_item_list posts ItemList' do
      items = [{ TextString: 'A' }]
      stub_post({ Command: 'Draw/SendHttpItemList', DeviceId: 'DEV123', ItemList: items }, error_code: 0)
      expect(client.send_http_item_list(item_list: items)).to be(true)
    end
  end

  context 'tools' do
    it '#set_timer posts timer params' do
      stub_post({ Command: 'Tools/SetTimer', DeviceId: 'DEV123', Minute: 1, Second: 30, Status: 1 }, error_code: 0)
      expect(client.set_timer(minute: 1, second: 30, status: 1)).to be(true)
    end

    it '#set_stopwatch toggles status' do
      stub_post({ Command: 'Tools/SetStopWatch', DeviceId: 'DEV123', Status: 0 }, error_code: 0)
      expect(client.set_stopwatch(status: 0)).to be(true)
    end

    it '#set_scoreboard updates scores' do
      stub_post({ Command: 'Tools/SetScoreBoard', DeviceId: 'DEV123', BlueScore: 5, RedScore: 10 }, error_code: 0)
      expect(client.set_scoreboard(blue_score: 5, red_score: 10)).to be(true)
    end

    it '#set_noise_status toggles noise meter' do
      stub_post({ Command: 'Tools/SetNoiseStatus', DeviceId: 'DEV123', NoiseStatus: 1 }, error_code: 0)
      expect(client.set_noise_status(noise_status: 1)).to be(true)
    end
  end

  context 'batch & external scripts' do
    it '#batch_command_list sends array' do
      cmds = [{ Command: 'A/B' }]
      stub_post({ Command: 'Draw/CommandList', DeviceId: 'DEV123', CommandList: cmds }, error_code: 0)
      expect(client.batch_command_list(command_list: cmds)).to be(true)
    end

    it '#use_http_command_source sends Url' do
      stub_post({ Command: 'Draw/UseHTTPCommandSource', DeviceId: 'DEV123', Url: 'http://x' }, error_code: 0)
      expect(client.use_http_command_source(url: 'http://x')).to be(true)
    end
  end
end
