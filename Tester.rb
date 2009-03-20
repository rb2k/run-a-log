class Tester
  $LOAD_PATH << "./ral/model"
  $LOAD_PATH << "./ral/parsers"
  $LOAD_PATH << "./ral/"
  $LOAD_PATH << "./lib/"
  require "rubygems"


  def initialize(filename)
    @filename = filename
    puts "Testing with: " + filename.to_s
  end


  def start

    require("Parser")
    puts "*****************TESTING-THE-PARSER*****************"
    my_start = Time.now
    p = Parser.new
    my_filled_container = p.parse(@filename)
    puts "Filename: " + my_filled_container.get_filename.to_s
    puts "Trackpoints: " + my_filled_container.get_trackpoints_number.to_s
    puts "Distance:" + my_filled_container.get_distance.to_s + "m"
    puts "Start Time:" + my_filled_container.get_time_start.to_s
    puts "End Time:" + my_filled_container.get_time_end.to_s
    puts "Duration:" + my_filled_container.get_duration.to_s + " seconds"
    puts "Duration in min: " + (my_filled_container.get_duration / 60).to_s + " minutes"
    puts "Average Speed: " + my_filled_container.get_speed_avg.to_s + " km/h"
    puts "Max Speed: " + my_filled_container.get_speed_max.to_s + " km/h"
    puts "Max Altitude: " + my_filled_container.get_altitude_max.to_s + " m"
    puts "Min Altitude: " + my_filled_container.get_altitude_min.to_s + " m"
    puts "Speeds: " + my_filled_container.get_speed_array.join("/")
    puts "Altitudes: " + my_filled_container.get_altitude_array.join("/")
    puts "Javascript for GMaps: " + my_filled_container.get_embedded_map_polyline.to_s
    puts "It took " + (Time.now - my_start).to_s + " seconds to get out all of the data initially"


    puts "*****************TESTING-THE-PERSISTANCE*****************"
    require("Persistence")
    require("dm-core")
    #DATAMAPPER

    puts "++++Setting up the database"
    #let's get a new persistant storage. As an argument, we pass our filled container
    my_persistance_storage = Persistence.new(my_filled_container)

    #enable query logging
    DataMapper::Logger.new(STDOUT, :info) # :off, :fatal, :error, :warn, :info, :debug

    #the database is a in-memory sqlite3 db
    DataMapper.setup(:default, 'sqlite3::memory:')
    puts "++++Creating Tables"
    #create the tables
    DataMapper.auto_migrate!

    puts "++++Telling the Persistance Class to put our Container in the Database"
    #save our container
    my_persistance_storage.save
    #my_filled_container.save


    sleep 5

    #load the first container with a distance > 2000
    #
    puts "++++Grabbing our first object from the DB (hopefully our container)"

    #Also possible: searching for one of the properties of the persistance class
    #blubb = Persistence.first(:distance.gt => 2000)

    #grabbing the first object inside the Database
    blubb = Persistence.first

    #we now can accecss all of the properties in "Persistence"
    puts "Persistance Filename: " + blubb.filename.to_s
    puts "Persistance Distance: " + blubb.distance.to_s
    puts "Persistance Time Start: " + blubb.start.to_s
    puts "Persistance Time end: " + blubb.end.to_s


    #now we want our original object back (with all the waypoints)
    #decompressing our stored container
    require "zlib"
    my_original_object = YAML::load(Zlib::Inflate.inflate(blubb.container))
    puts "++++Getting our original \"container\" back from the Database"
    puts "We go our Object back, it's a(n): " + my_original_object.class.to_s
    puts "The trip inside it started back then " + my_original_object.get_time_start.to_s
    puts "... and ended back then " + my_original_object.get_time_end.to_s

  end

end