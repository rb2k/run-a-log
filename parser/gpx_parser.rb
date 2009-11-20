def parse_gpx(filehandle)

  
  require "time"

  #creating our container which will be returned by the parser
  my_container = Container.new

  @currently_in_trackpoint = false
  @temp_stamp = nil
  filehandle.each_line do |line|

    if line.include?("<trkpt")
      #puts "trackpoint started"
      @temp_stamp = Timestamp.new("temp")
      @currently_in_trackpoint = true
    elsif line.include?("</trkpt>")
      #puts "trackpoint ended"
      #ok, we should by now know our time, so we simply generate a new container, copy the stuff from the old one and delete the old one
      my_container._timestamps[(@temp_stamp.get_data(:time))]=@temp_stamp
      @temp_stamp = nil
      #and we're finished editing our trackpoint
      @currently_in_trackpoint = false
    end

    #USUAL DATA
    if (@currently_in_trackpoint)
      if line.include?("lat=")
        @temp_stamp.set_data(:latitude, Float(line.split("lat=\"")[1].split('"')[0]))
      end

      if line.include?("lon=")
        @temp_stamp.set_data(:longitude, Float(line.split("lon=\"")[1].split('"')[0]))
      end

      if line.include?("ele")
        @temp_stamp.set_data(:altitude, Float(line.split("<ele>")[1].split("</ele>")[0]))
      end
        
      if line.include?("time")
        @temp_stamp.set_data(:time, Time.parse(line.split("<time>")[1].split("</time>")[0]))
      end
      #META DATA
      if line.include?("gpxdata:hr")
        @temp_stamp.set_meta(:heartrate, Integer(line.split("<gpxdata:hr>")[1].split("</gpxdata:hr>")[0]))
      end


    end
  end
    

  #returning my_container
  my_container
end