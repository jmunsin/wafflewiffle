require 'rubygems'
require 'sinatra'
require 'bluecloth'
require 'RMagick'
require 'dm-core'

# wafflewiffle (c) Jonas Munsin (jmunsin@gmail.com)
# released under GPLv3 or later

pvdir="wafflewiffle"

class Picture
  include DataMapper::Resource
  property :id,         Serial
  property :name,       String, :key => true
  property :angle,      Float
end

#use Rack::Auth::Basic do |username, password|
#    [username, password] == ['test', 'test']
#end

configure do
  DataMapper.setup(:default, "sqlite3:///#{Dir.pwd}/test.db")
  #DataMapper.setup(:default, "mysql://root:pass@localhost/sinatratest")
  #Picture.auto_migrate!
  Picture.auto_upgrade!
#  DataMapper::Logger.new(STDOUT, :debug)
end

def get_dirs(dir, sub)
  dir = ""
  dir = "/" + sub if sub
  listing = ""
  Dir.entries("wafflewiffle" + dir).sort.each { |fn|
    if File.stat("wafflewiffle" + dir + "/" + fn).directory?
      if fn != "."
        if fn != ".."
          if sub
            listing += "* [#{fn}](/wafflewiffle#{dir}/#{fn})\n"
          else
            listing += "* [#{fn}](/wafflewiffle/#{fn})\n"
          end
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
        listing += "<a href=\"/wafflewiffle/#{sub}/#{fn}?size=normal\">"
        listing += "<img src=\"/wafflewiffle/#{sub}/#{fn}?size=thumb\" name=\"#{sub.gsub(".", "").gsub("_", "")}/#{fn.gsub(".", "").gsub("_", "")}\">"
        listing += "</a>"
        listing += <<EOS1
        <form>
        <input type="button" value="<" onClick='rotateImage(\"#{sub}/#{fn}\", -90);'>
        <input type="button" value="^" onClick='rotateImage(\"#{sub}/#{fn}\", 180);'>
        <input type="button" value=">" onClick='rotateImage(\"#{sub}/#{fn}\", 90);'>
        </form>
EOS1
      else
        listing += "<a href=\"/wafflewiffle/#{fn}?size=normal\">"
        listing += "<img src=\"/wafflewiffle/#{fn}?size=thumb\" name=\"#{fn.gsub(".", "").gsub("_", "")}\">"
        listing += "</a>"
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
  img = nil
  if params["size"] == "thumb"
    imgs = Magick::Image.read(pvdir + "/" + params["splat"].join("/") + suffix) { self.size = "270x" }
    img = imgs.first
  else
    imgs = Magick::Image.read(pvdir + "/" + params["splat"].join("/") + suffix)
    img = imgs.first
    if params["size"] == "normal"
      img.change_geometry("1024x") { |c, r|
        img.resize!(c, r)
      }
    end
  end
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
  str += "<script type=\"text/javascript\" src=\"/wafflewiffle/jquery-1.3.js\"></script>\n"
  str += "<script type=\"text/javascript\">\n"
  str += <<EOS
    function rotateImage(image, degree) {
        $.get("rotate", {angle: degree, img: image});
        var now = new Date();
        if (document.images) {
          str = image.replace(/\\./g, "").replace(/_/g, "");
          document.images[str].src = "/wafflewiffle/" + image + "?unique=" + now.getTime() + "&size=thumb" ;
        }
    }
EOS
  str += "</script>\n"
  str += "</head>\n"

  str
end

def rotate(params)
  pic = Picture.first(:name => params["img"])
  pic = Picture.new(:name => params["img"]) if pic == nil
  pic.angle = 0 if pic.angle == nil
  pic.angle += params[:angle].to_f
  pic.save
end

get '/wafflewiffle/jquery-1.3.js' do
  File.read("public/jquery-1.3.js")
end

get '/wafflewiffle/*/rotate' do
  rotate(params)
end

get '/wafflewiffle/rotate' do
  rotate(params)
end

get '/wafflewiffle/' do
  str = get_javascript
  str += get_page(pvdir)
  str += "</html>\n"
end

get '/wafflewiffle/*.jpg' do
  get_jpg(pvdir, params, ".jpg")
end

get '/wafflewiffle/*.JPG' do
  get_jpg(pvdir, params, ".JPG")
end

get '/wafflewiffle/favicon.ico' do
  nil
end

get '/wafflewiffle/*' do
  str = get_javascript
  str += get_page(pvdir, params["splat"].join("/"))
  str += "</html>\n"
end

get '/' do
  redirect '/wafflewiffle/'
end

get '/wafflewiffle' do
  redirect '/wafflewiffle/'
end

