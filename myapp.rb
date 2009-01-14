require 'rubygems'
require 'sinatra'
require 'bluecloth'
require 'RMagick'
require 'dm-core'

pvdir="/home/jm/code/photoviewer/data"

class Picture
  include DataMapper::Resource
  property :id,         Serial
  property :name,       String, :key => true
  property :angle,      Float
end

configure do
  DataMapper.setup(:default, "sqlite3:///#{Dir.pwd}/test.db")
  #Picture.auto_migrate!
end

def get_dirs(dir, sub)
  dir += "/" + sub if sub
  listing = ""
  Dir.entries(dir).sort.each { |fn|
    if File.stat(dir + "/" + fn).directory?
      if fn != "."
        if fn != ".."
          listing += "* [#{fn}](#{fn})\n"
        else
        end
      end
    end
  }
  BlueCloth.new(listing).to_html
end

def get_files(dir, sub)
  dir += "/" + sub if sub
  listing = ""
  Dir.entries(dir).sort.each { |fn|
    if File.stat(dir + "/" + fn).file?
      if sub
        listing += "![#{sub}/#{fn}](#{sub}/#{fn})\n"
      else
        listing += "![#{fn}](#{fn})\n"
        listing += "[<](#{fn}/rotate/l)\n"
        listing += "[^](#{fn}/rotate/u)\n"
        listing += "[>](#{fn}/rotate/r)\n"
      end
    end
  }
  BlueCloth.new(listing).to_html
end

def get_page(dir, sub=false)
  d = get_dirs(dir, sub) + BlueCloth.new("---\n").to_html + get_files(dir, sub)
end

def get_jpg(pvdir, params, suffix)
  imgs = Magick::Image.read(pvdir + "/" + params["splat"].join("/") + suffix) { self.size = "270x" }
  img = imgs.first
  pic = Picture.first(:name => params["splat"].join("/") + suffix)
  if pic != nil and pic.angle != nil and pic.angle != 0
    img.rotate!(pic.angle)
  end
  #pic = Picture.new(:name => params["splat"].join("/") + suffix)
  #pic.angle=-90.0
  #pic.save
  content_type 'image/jpg'
  img.to_blob { fileformat="JPEG" }
end

get '/*/rotate/r' do
  p "a"
end

get '/' do
  get_page(pvdir)
end

get '/*.jpg' do
  get_jpg(pvdir, params, ".jpg")
end

get '/*.JPG' do
  get_jpg(pvdir, params, ".JPG")
end

get '/*' do
  get_page(pvdir, params["splat"].join("/"))
end

