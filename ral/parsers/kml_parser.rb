def parse_kml(filehandle)
  #require "time"
     
  my_container = Container.new
  counter = 0
  time =""
     
  @in_timestamp = false
  @in_point = false
     
  #get the information out of the kml file
  filehandle.each_line do |line|
        
    #  check for tags that contain necessary data
    if line.include?("<TimeStamp>")
      #puts "TimeStamp start"
      @in_timestamp = true
        
    elsif line.include?("</TimeStamp>")
      #puts "TimeStamp end"
      @in_timestamp = false
        
    elsif line.include?("<Point>")
      #puts "Trackpoint start"
      @in_point= true
                  
    elsif line.include?("</Point>")
      #puts "Trackpoint end"
      @in_point = false
      #puts "----"
    end #if
        
    # <timestamp>
    #   <when> TIMEDATA </when>
    #</timestamp>
    if (@in_timestamp)
      if line.include?("when")
        time = line.split("<when>")[1].split("</when>")[0] +"Z"
        my_container.new_timestamp(time)
             
        #puts "Timestamp: " + time
      end # if include
    end #if timestamp
        
    # <point>
    #   <coordinates> LON, LAT, ELE </coordinates>
    # </point>
    if (@in_point)
      if line.include?("coordinates")
        coords = (line.split("<coordinates>")[1].split("</coordinates>")[0]).split(",")
        my_container._timestamps[time].set_data(:longitude, Float(coords[0]))
        my_container._timestamps[time].set_data(:latitude, Float(coords[1]))
        my_container._timestamps[time].set_data(:altitude, Float(coords[2]))

        #puts "longitude: " + coords[0] + "; latitude: " + coords[1] + "; altitude: " + coords[2]
        counter+=1
      end # if line.include
    end #if @in_point
        
  end #do
  my_container
      
end #def