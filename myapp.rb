require 'rubygems'
require 'sinatra'
require 'bluecloth'
require 'RMagick'

pvdir="/home/jm/code/photoviewer/data"

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
      end
    end
  }
  BlueCloth.new(listing).to_html
end

def get_page(dir, sub=false)
  d = get_dirs(dir, sub) + BlueCloth.new("---\n").to_html + get_files(dir, sub)
end

def get_jpg(pvdir, params, suffix)
  imgs = Magick::Image.read(pvdir + "/" + params["splat"].join("/") + suffix)
  img = imgs.first
  img.resize!(0.1)
  content_type 'image/jpg'
  img.to_blob { fileformat="JPEG" }
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

