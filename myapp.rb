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
#        l  = "![#{sub}/#{fn}](#{sub}/#{fn})\n"
#        l += "[<](rotate?angle=-90&img=#{sub}/#{fn})\n"
#        l += "[^](rotate?angle=180&img=#{sub}/#{fn})\n"
#        l += "[>](rotate?angle=90&img=#{sub}/#{fn})\n"
#        listing += BlueCloth.new(l).to_html
        listing += "<img src=\"#{sub}/#{fn}\" name=\"#{sub}/#{fn.gsub(".", "").gsub("_", "")}\">"
        listing += <<EOS1
        <form>
        <input type="button" value="<" onClick='rotateImage(\"#{sub}/#{fn}\", -90);'>
        <input type="button" value="^" onClick='rotateImage(\"#{sub}/#{fn}\", 180);'>
        <input type="button" value=">" onClick='rotateImage(\"#{sub}/#{fn}\", 90);'>
        </form>
EOS1
      else
        listing += "<img src=\"#{fn}\" name=\"#{fn.gsub(".", "").gsub("_", "")}\">"
        listing += <<EOS2
        <form>
        <input type="button" value="<" onClick='rotateImage(\"#{fn}\", -90);'>
        <input type="button" value="^" onClick='rotateImage(\"#{fn}\", 180);'>
        <input type="button" value=">" onClick='rotateImage(\"#{fn}\", 90);'>
        </form>
EOS2
      end
    end
  }
  listing
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
  content_type 'image/jpg'
  img.to_blob { fileformat="JPEG" }
end

def get_javascript
  str = ""
  str += "<html>\n"
  str += "<head>\n"
  str += "<script type=\"text/javascript\" src=\"jquery-1.3.js\"></script>\n"
  str += "<script type=\"text/javascript\">\n"
  str += <<EOS
    function rotateImage(image, degree) {
        $.get("rotate", {angle: degree, img: image});
        var now = new Date();
        if (document.images) {
          str = image.replace(/\\./, "").replace(/_/, "");
          document.images[str].src = image + '?' + now.getTime();
        }
    }
EOS
  str += "</script>\n"
  str += "</head>\n"

  str
end

get '/rotate' do
  pic = Picture.first(:name => params["img"])
  pic = Picture.new(:name => params["img"]) if pic == nil
  pic.angle = 0 if pic.angle == nil
  pic.angle += params[:angle].to_f
  pic.save
end

get '/' do
  str = get_javascript
  str += get_page(pvdir)
  str += "</html>\n"
end

get '/*.jpg' do
  get_jpg(pvdir, params, ".jpg")
end

get '/*.JPG' do
  get_jpg(pvdir, params, ".JPG")
end

get '/*' do
  str = get_javascript
  str += get_page(pvdir, params["splat"].join("/"))
  str += "</html>\n"
end

