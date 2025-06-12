require 'spec_helper'
require 'pixoo_pusher/frame_buffer'
require 'base64'

RSpec.describe PixooPusher::FrameBuffer do
  subject { described_class.new(width: 4, height: 2) }

  it 'initializes all pixels to black' do
    expect(subject.pixels).to all(eq(0))
    expect(subject.pixels.size).to eq(8)
  end

  describe '#set_pixel' do
    it 'sets the correct index for valid coordinates' do
      subject.set_pixel(1, 1, 0xFF00FF)
      expect(subject.pixels[1 + 1 * 4]).to eq(0xFF00FF)
    end

    it 'masks out extra bits beyond 24-bit' do
      subject.set_pixel(0, 0, 0x1_FF00FF)
      expect(subject.pixels[0]).to eq(0xFF00FF)
    end

    it 'raises IndexError for out-of-bounds coordinates' do
      expect { subject.set_pixel(4, 0, 0) }.to raise_error(IndexError)
      expect { subject.set_pixel(0, 2, 0) }.to raise_error(IndexError)
      expect { subject.set_pixel(-1, 0, 0) }.to raise_error(IndexError)
    end
  end

  describe 'export formats' do
    before do
      colors = [0xFF0000, 0x00FF00, 0x0000FF, 0xFFFF00]
      colors.each_with_index { |c, i| subject.set_pixel(i, 0, c) }
    end

    it '#to_flat_array returns the raw pixel values' do
      expect(subject.to_flat_array[0,4]).to eq([0xFF0000, 0x00FF00, 0x0000FF, 0xFFFF00])
    end

    it '#to_binary_rgb packs into bytes correctly' do
      bin = subject.to_binary_rgb[0,12]
      expect(bin.bytes).to eq([255,0,0, 0,255,0, 0,0,255, 255,255,0])
    end

    it '#to_base64_rgb matches Base64.strict_encode64 result' do
      expect(subject.to_base64_rgb).to eq(Base64.strict_encode64(subject.to_binary_rgb))
    end
  end
end
