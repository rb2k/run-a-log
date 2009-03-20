require("rubygems")
require("dm-core")

class Persistence
include DataMapper::Resource
  property :filename,       String, :key => true
  property :start,  DateTime
  property :end,      DateTime
  property :speed_avg,       Float
  property :speed_max,       Float
  property :distance,       Float
  property :duration,       Float
  #property :comment,       String
  #property :container,       Object, :lazy => true

   def initialize(my_container)
     self.start = my_container.get_time_start
     self.end = my_container.get_time_end
     self.speed_avg = my_container.get_speed_avg
     self.speed_max = my_container.get_speed_max
     self.distance = my_container.get_distance
     self.duration = my_container.get_duration
     self.filename = my_container.get_filename

     #require("yaml")
     #require("zlib")

     #compress our container
    # self.container = Zlib::Deflate.deflate(my_container.to_yaml,9)

     #size unzipped:  462546
     #size zipped:    42545
     #puts "XXXXXXXXXXXXsize unzipped: " + my_container.to_yaml.length.to_s
     #puts "XXXXXXXXXXXXsize zipped: " + self.container.length.to_s
     #sleep 9
     
   end


  
end