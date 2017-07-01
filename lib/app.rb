require 'sinatra'
require 'json'
require 'pry-remote'
require 'sinatra/cross_origin'
require 'chunky_png'
require_relative './nerual-net/net'

configure do
  set :server, :puma
  enable :cross_origin
end

set :root, 'lib/app'

post '/predict' do
  canvas = downsample ChunkyPNG::Canvas.from_data_url(request.body.read)
  random_cropped = Array.new(4) { canvas.crop(0, 0, 28, 28) }
  net = Net.load_network('lib/nerual-net/examples/mnist_model.dump')
  predict_sums = Array.new(10, 0)
  random_cropped.each do |cropped|
    pixels = normalize_pixels cropped
    predict = net.process(pixels)
    predict.values.each_with_index { |val, i| predict_sums[i] += val }
  end
  { prediction: Util.decode_output(predict_sums) }.to_json
end

get '/' do
  render :html, :index
end

private

def downsample(canvas)
  canvas.trim!
  size = [canvas.width, canvas.height].max
  square = ChunkyPNG::Canvas.new(size, size, ChunkyPNG::Color::TRANSPARENT)
  offset_x = find_offset(size, canvas.width)
  offset_y = find_offset(size, canvas.height)
  square.compose!(canvas, offset_x, offset_y)
  square.resample_bilinear!(20, 20)
  square.tap { |s| s.border!(4, ChunkyPNG::Color::TRANSPARENT) }
end

def find_offset(size, dimension)
  (size - dimension) / 2
end

def normalize_pixels(canvas)
  pixels = []
  28.times { |y| 28.times { |x| pixels << canvas[x, y] } }
  min = pixels.min
  max = pixels.max
  pixels.tap { |pix| pix.map { |p| Util.normalize(p, min, max, 0, 1) } }
end

module Util
  class << self
    def normalize(val, from_low, from_high, to_low, to_high)
      (val - from_low) * (to_high - to_low) / (from_high - from_low).to_f
    end

    def decode_output(output)
      (0..9).max_by { |i| output[i] }
    end
  end
end
