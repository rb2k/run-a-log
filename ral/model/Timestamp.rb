class Timestamp 
#for usage hints: look at the Container.rb





#when initializing a timestamp, we have to at least have the time itself
def initialize(time)
  #this is where we'll save all the data to
  @data = Hash.new
  @meta = Hash.new

#this array keeps a list of all the data we allow in the set_data method. basically just the stuff we get from EVERY format
#I think it's save to share this one between ALL of the timestamps --> global variable
#It's also better to use symbols (:bla) as those strings will be used pretty often and we don't want memory consumption to skyrocket
 $allowed_ts_data=[
  :time,
  :latitude,
  :longitude,
  :altitude
  ]
  
  
  self.set_data(:time, time)
  
end


def set_data(data_name, data_value)
  if $allowed_ts_data.include?(data_name)
    @data["#{data_name}"] = data_value  
  else
      puts "'#{data_name.to_s}' is not allowed as data, you could try adding it as metadata instead"
  end
end

def get_data(data_name)
  #if $allowed_ts_data.include?(data_name)
    @data["#{data_name}"]  
  #else
  #   puts "'#{data_name.to_s}' is not allowed as data, did you want to fetch some metadata instead?"
  # end
end



def set_meta(data_name, data_value)
@meta["#{data_name}"] = data_value  
end

def get_meta(data_name)
@meta["#{data_name}"]  
end



end