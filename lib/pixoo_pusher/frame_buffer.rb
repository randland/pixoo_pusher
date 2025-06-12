module PixooPusher
  # A 2-D matrix of RGB LEDs stored as 24-bit integers (0xRRGGBB).
  # Provides pixel-level access and exports in various formats.
  class FrameBuffer
    attr_reader :width, :height, :pixels

    # Initialize a width×height buffer, defaulting to 64×32
    # @param width [Integer]
    # @param height [Integer]
    def initialize(width: 64, height: 32)
      @width, @height = width, height
      @pixels = Array.new(width * height, 0)
    end

    # Set a single pixel; raises IndexError if x or y is out of range
    # @param x [Integer] column index (0...width)
    # @param y [Integer] row index (0...height)
    # @param color [Integer] any Integer; masked to 24 bits
    def set_pixel(x, y, color)
      unless x.between?(0, width - 1) && y.between?(0, height - 1)
        raise IndexError, "coordinates (#{x}, #{y}) out of bounds"
      end

      idx = y * width + x
      pixels[idx] = color & 0xFFFFFF
    end

    # Return a copy of the raw pixel array [0xRRGGBB, ...]
    # @return [Array<Integer>]
    def to_flat_array
      pixels.dup
    end

    # Pack the pixels into a binary RGB string: [R,G,B] per pixel
    # @return [String]
    def to_binary_rgb
      pixels
        .map { |c| [(c >> 16) & 0xFF, (c >> 8) & 0xFF, c & 0xFF] }
        .flatten
        .pack('C*')
    end

    # Base64-encode the binary RGB data
    # @return [String]
    def to_base64_rgb
      require 'base64'
      Base64.strict_encode64(to_binary_rgb)
    end
  end
end
