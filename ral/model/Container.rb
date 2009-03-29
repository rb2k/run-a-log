class Container 

  require "Timestamp.rb"

  attr_accessor :_timestamps
    
  $allowed_container_data=[
    :filename,
    :start,
    :end,
    :comment,
    :weather,
    :distance,
    :duration,
    :speed_avg,
    :speed_max,
    :elevation,
    :hr_max,
    :hr_avg
  ]
  
  
  def initialize
    @_data = Hash.new
    @_timestamps = Hash.new
  end



  def set_data(data_name, data_value)
    if $allowed_container_data.include?(data_name)
      @_data["#{data_name}"] = data_value
    else
      puts "'#{data_name.to_s}' is not allowed as data in the container"
    end
  end

  def get_data(data_name)
    if $allowed_container_data.include?(data_name)
      @_data["#{data_name}"]
    else
      puts "'#{data_name.to_s}' is not allowed as data in the container"
    end
  end

  
  def new_timestamp(name)
    @_timestamps["#{name}"] = Timestamp.new(name)
  end

  #def add_timestamp(my_timestamp)
  #self["#{my_timestamp.get_name}"] = my_timestamp
  #end
  def get_trackpoints_number
    @_timestamps.size

  end

  def get_filename
    self.get_data(:filename)
  end

  def get_distance
    require "geo"
    if !self.get_data(:distance).nil?
      #<debug>
      #puts "debug: cached distance data found!"
      #</debug>
      self.get_data(:distance)
    end

    mathy = Geo.new
    distance = 0.0
    first_pair  = nil
  
    keys_over_time = @_timestamps.keys.sort
  
    
    keys_over_time.each { |key|
      if first_pair.nil?
        first_pair = @_timestamps[key]
        next
      end

      second_pair = @_timestamps[key]
      dst = mathy.distance_in_m(first_pair.get_data(:latitude),
                                first_pair.get_data(:longitude),
                                 second_pair.get_data(:latitude),
                                 second_pair.get_data(:longitude))
      distance+=dst
    
      #ok, now we want to get the distance from the second pair to the following trackpoint
      first_pair = second_pair
    }

    distance.round
    self.set_data(:distance, distance.round)
  end

  def get_duration
    require "time"
    if !self.get_data(:duration).nil?
      #<debug>
      #puts "debug: cached duration data found!"
      #</debug>
      return self.get_data(:duration)
    end

    duration = get_time_end - get_time_start

    self.set_data(:duration, duration)

    duration.round
  end

  def get_duration_min
    (self.get_duration/60).to_i
  end

  def get_time_start
    if !self.get_data(:start).nil?
      #<debug>
      #puts "debug: cached start_time data found!"
      #</debug>
      return self.get_data(:start)
    end

    
    sorted = @_timestamps.keys.sort
    if !sorted.first.is_a?(Time)
      require "time"
      start_time = Time.parse(sorted.first)
    elsif
      start_time = sorted.first
    end
    
    self.set_data(:start, start_time )

    start_time
  end


  def get_time_end
    if !self.get_data(:end).nil?
      #<debug>
      #puts "debug: cached end_time data found!"
      #</debug>
      return self.get_data(:end)
    end

    sorted = @_timestamps.keys.sort
    if !sorted.last.is_a?(Time)
      require "time"
      end_time = Time.parse(sorted.last)
    elsif
      end_time = sorted.last
    end

    self.set_data(:end, end_time )

    end_time
  end

  def get_speed_avg

    if !self.get_data(:speed_avg).nil?
      #<debug>
      #puts "debug: cached end_time data found!"
      #</debug>
      return self.get_data(:speed_avg)
    end


    distance = self.get_distance.to_f
    duration = self.get_duration.to_f

    speed_avg = (distance / duration) * 3.6
    self.set_data(:speed_avg, speed_avg )

    speed_avg
  end

  def get_speed_max
    my_speeds = get_speed_array
    my_speeds.sort!
    #Filter single speeds that are unlikely. if there is one value that is 10% faster than the 2nd fastest value, delete it and try again
    while (my_speeds[-1] > (my_speeds[-2] * 1.1)) do
      my_speeds.delete(my_speeds.last)
    end

    my_speeds.max
  end


  def get_speed_array

    require "geo"
    mathy = Geo.new
    speed_array = Array.new
    first_pair  = nil

    keys_over_time = @_timestamps.keys.sort


    keys_over_time.each { |key|
      if first_pair.nil?
        first_pair = @_timestamps[key]
        next
      end


      second_pair = @_timestamps[key]
      dst = mathy.distance_in_m(first_pair.get_data(:latitude),first_pair.get_data(:longitude),second_pair.get_data(:latitude),second_pair.get_data(:longitude))

      if first_pair.get_data(:time).is_a?(Time)
        time = second_pair.get_data(:time) - first_pair.get_data(:time)
      else
        time = Time.parse(second_pair.get_data(:time)) - Time.parse(first_pair.get_data(:time))
      end
      
      speed_array.push(((dst/time)*3.6).round)

      first_pair = second_pair
    }
    speed_array
  end

  def get_altitude_array

    keys_over_time = @_timestamps.keys.sort
    altitude_array = Array.new

    keys_over_time.each { |key|
      altitude_array.push(@_timestamps[key].get_data(:altitude))
    }

    altitude_array
  end

  def get_altitude_min
    get_altitude_array.min
  end

  def get_altitude_max
    get_altitude_array.max
  end

 def get_elevation
    if !self.get_data(:elevation).nil?
      #<debug>
      #puts "debug: cached end_time data found!"
      #</debug>
      return self.get_data(:elevation)
    end

    self.set_data(:elevation, get_altitude_array.max - get_altitude_array.min)
    return self.get_data(:elevation)
  end


  def heartrates?
    get_heartrate_array.size > 0
  end

  def get_heartrate_array
    keys_over_time = @_timestamps.keys.sort
    hr_array = Array.new

    keys_over_time.each { |key|
      hr_val = @_timestamps[key].get_meta(:heartrate)
      if hr_val != nil
        hr_array.push(hr_val)
      end
    }

    hr_array
  end

  def get_hr_min
    if heartrates?
      get_heartrate_array.min
    else
      0
    end
  end

  def get_hr_max
    if !self.get_data(:hr_max).nil?
      #<debug>
      #puts "debug: cached end_time data found!"
      #</debug>
      return self.get_data(:hr_max)
    end
    
    if heartrates?
      self.set_data(:hr_max, get_heartrate_array.max)
    else
      self.set_data(:hr_max, 0)
    end
    
    return self.get_data(:hr_max)
  end

  def get_hr_avg
    if !self.get_data(:hr_avg).nil?
      #<debug>
      #puts "debug: cached end_time data found!"
      #</debug>
      return self.get_data(:hr_avg)
    end

  #if there are heartrates, we'll sum them up and divide them by their amount --> average
  @hrates = get_heartrate_array
    if @hrates.size > 0
        my_sum = 0

        @hrates.each{|hr| my_sum += hr }
        self.set_data(:hr_avg, my_sum/@hrates.size)
        return self.get_data(:hr_avg)
    else
        return 0
    end
  end

  def get_lat_lon
    lat_lon_array = Array.new


    @_timestamps.keys.sort.each { |tempstamp|

      lat = @_timestamps[tempstamp].get_data(:latitude)
      lon = @_timestamps[tempstamp].get_data(:longitude)
      lat_lon_array.push([lat,lon])
    }
    lat_lon_array

  end


  def get_embedded_map_polyline
    #this is the javascript part that is used to generate the map later on
    #require("GMapPolylineEncoder")
    require("lib/gmap_polyline_encoder.rb")
    encoder = GMapPolylineEncoder.new()
    lat_lon_array = Array.new


    @_timestamps.keys.sort.each { |tempstamp|
          
      lat = @_timestamps[tempstamp].get_data(:latitude)
      lon = @_timestamps[tempstamp].get_data(:longitude)
      lat_lon_array.push([lat,lon])
    }


    result = encoder.encode( lat_lon_array )
    #javascript = ""
    #javascript << " var myLine = new GPolyline.fromEncoded({\n"
    #javascript << " color: \"#FF0000\",\n"
    #javascript << " weight: 10,\n"
    #javascript << " opacity: 0.5,\n"
    #javascript << " zoomFactor: #{result[:zoomFactor]},\n"
    #javascript << " numLevels: #{result[:numLevels]},\n"
    #javascript << " points: \"#{result[:points]}\",\n"
    #javascript << " levels: \"#{result[:levels]}\"\n"
    #javascript << " });"

  end



end #class





