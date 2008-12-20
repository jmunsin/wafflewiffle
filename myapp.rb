require 'rubygems'
require 'sinatra'
require 'bluecloth'

pvdir="/home/jm/code/photoviewer/testphotos"

def renderdir(dir)
  listing = ""
  Dir.foreach(dir) { |fn|
    if fn != "."
      listing += "* [#{fn}](#{fn})\n"
    end
  }
  BlueCloth.new(listing).to_html
end

get '/' do
  renderdir(pvdir)
end

