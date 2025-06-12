require 'spec_helper'
require 'pixoo_pusher/protocol/cloud_client'
require 'json'

RSpec.describe PixooPusher::Protocol::CloudClient do
  let(:transport) { instance_double('PixooPusher::Transport') }
  subject(:client) { described_class.new(transport) }

  describe '#discover_devices' do
    it 'posts to the correct endpoint and returns DeviceList' do
      device_list = [{ DeviceId: 1 }, { DeviceId: 2 }]
      response_body = { DeviceList: device_list }.to_json
      resp = double('Response', body: response_body)

      expect(transport).to receive(:post)
        .with('/Device/ReturnSameLANDevice', payload: {})
        .and_return(resp)

      expect(client.discover_devices).to eq(device_list)
    end

    it 'raises TransportError on invalid JSON' do
      resp = double('Response', body: 'invalid json')
      expect(transport).to receive(:post).and_return(resp)
      expect { client.discover_devices }
        .to raise_error(PixooPusher::TransportError, /Cloud JSON parse error/)
    end
  end

  describe '#list_fonts' do
    it 'posts with FontType and returns FontList' do
      fonts = [{ FooFont: true }]
      response_body = { FontList: fonts }.to_json
      resp = double('Response', body: response_body)

      expect(transport).to receive(:post)
        .with('/Device/GetTimeDialFontList', payload: { FontType: 5 })
        .and_return(resp)

      expect(client.list_fonts(font_type: 5)).to eq(fonts)
    end
  end

  describe '#list_dials' do
    it 'posts with DialType and Page and returns dials and total' do
      dial_list = [{ ClockId: 1, Name: 'A' }]
      response_body = { DialList: dial_list, TotalNum: 42 }.to_json
      resp = double('Response', body: response_body)

      expect(transport).to receive(:post)
        .with('/Channel/GetDialList', payload: { DialType: 'game', Page: 2 })
        .and_return(resp)

      expect(client.list_dials(dial_type: 'game', page: 2))
        .to eq(dials: dial_list, total: 42)
    end

    it 'uses default page of 1 when not provided' do
      response_body = { DialList: [], TotalNum: 0 }.to_json
      resp = double('Response', body: response_body)

      expect(transport).to receive(:post)
        .with('/Channel/GetDialList', payload: { DialType: 'all', Page: 1 })
        .and_return(resp)

      expect(client.list_dials(dial_type: 'all'))
        .to eq(dials: [], total: 0)
    end
  end

  describe '#list_dial_types' do
    it 'posts to the correct endpoint and returns DialTypeList' do
      types = ['Social', 'Game']
      response_body = { DialTypeList: types }.to_json
      resp = double('Response', body: response_body)

      expect(transport).to receive(:post)
        .with('/Channel/GetDialType', payload: {})
        .and_return(resp)

      expect(client.list_dial_types).to eq(types)
    end
  end

  describe '#list_galleries' do
    it 'posts with GalleryType and Page and returns galleries and total' do
      galleries = [{ Id: 1 }, { Id: 2 }]
      response_body = { GalleryList: galleries, TotalNum: 7 }.to_json
      resp = double('Response', body: response_body)

      expect(transport).to receive(:post)
        .with('/Channel/GetGalleryList', payload: { GalleryType: 'bg', Page: 3 })
        .and_return(resp)

      expect(client.list_galleries(gallery_type: 'bg', page: 3))
        .to eq(galleries: galleries, total: 7)
    end

    it 'defaults page to 1 when not provided' do
      galleries = []
      response_body = { GalleryList: galleries, TotalNum: 0 }.to_json
      resp = double('Response', body: response_body)

      expect(transport).to receive(:post)
        .with('/Channel/GetGalleryList', payload: { GalleryType: 'icon', Page: 1 })
        .and_return(resp)

      expect(client.list_galleries(gallery_type: 'icon'))
        .to eq(galleries: galleries, total: 0)
    end
  end

  describe '#list_images' do
    it 'posts with GalleryId and Page and returns images and total' do
      images = [{ FileId: 'A' }, { FileId: 'B' }]
      response_body = { ImageList: images, TotalNum: 5 }.to_json
      resp = double('Response', body: response_body)

      expect(transport).to receive(:post)
        .with('/Channel/GetImageList', payload: { GalleryId: 'X', Page: 2 })
        .and_return(resp)

      expect(client.list_images(gallery_id: 'X', page: 2))
        .to eq(images: images, total: 5)
    end

    it 'defaults page to 1 when not provided' do
      images = []
      response_body = { ImageList: images, TotalNum: 0 }.to_json
      resp = double('Response', body: response_body)

      expect(transport).to receive(:post)
        .with('/Channel/GetImageList', payload: { GalleryId: 'Y', Page: 1 })
        .and_return(resp)

      expect(client.list_images(gallery_id: 'Y'))
        .to eq(images: images, total: 0)
    end
  end
end
