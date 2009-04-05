require "rubygems"
require 'nokogiri' 
require "time"

def parse_gpx(filehandle)
#creating our container which will be returned by the parser
my_container = Container.new

doc = Nokogiri.HTML(filehandle.read)
doc.search("//trkpt").each do |trackpoint|
  @temp_stamp = Timestamp.new("temp")
  
  lon = Float(trackpoint["lon"])
  @temp_stamp.set_data(:longitude, lon)
  
  lat = Float(trackpoint["lat"])
  @temp_stamp.set_data(:latitude, lat)
  
  ele = Float(trackpoint.at("ele").inner_text)
  @temp_stamp.set_data(:altitude, ele)
  
  time = Time.parse(trackpoint.at("time").inner_text)
  @temp_stamp.set_data(:time, time)
  
  unless trackpoint.at("gpxdata:hr").nil?
    heartrate = Integer(trackpoint.at("gpxdata:hr"))
    @temp_stamp.set_meta(:heartrate, heartrate)
  end
  
  my_container._timestamps[(@temp_stamp.get_data(:time))] = @temp_stamp
  
end
  

  #returning my_container
  my_container
  
end