require 'rubygems'
require 'sinatra'


configure do

  $LOAD_PATH << "./ral/model"
  $LOAD_PATH << "./ral/parsers"
  $LOAD_PATH << "./ral/"
  $LOAD_PATH << "./lib/"

  require "yaml"
  require "dm-core" #sudo gem install dm-core
  require "dm-aggregates" #sudo gem install dm-aggregates
  #sudo gem install do_mysql
  require 'google_chart'  #sudo gem install gchartb
  require "Persistence"
  require "Parser"



  puts "*****************SETTING_UP_CONFIGURATION**********************"

  #'''''''''READING CONFIG FILE''''''''
  puts "reading config file config/config.yml"
  
  config = YAML.load_file("config/config.yml")

  #adding the stuff from inside the config to sinatras options hash
  #accessing e.g. the :data_folder option via Sinatra::Application.data_folder
	set :google_maps_key => config["google_maps_key"],
    :data_folder => config["data_folder"],
    :allowed_extensions => config["allowed_extensions"],
    :admin_pass => config["admin_pass"],
    :db_connect_string => config["db_connect_string"]

  #'''''''''DATABASE CONNECTION''''''''
  

  DataMapper.setup(:default, Sinatra::Application.db_connect_string)
  begin
    puts "Found #{Persistence.all.size} entries"
  rescue Exception
    puts "No Database table found, creating it..."
    DataMapper.auto_migrate!
  end
  puts "*****************FINISHED_CONFIGURATION**********************"
end



get '/' do
  #get a list of our files
  my_files = Array.new
  Dir.entries(Sinatra::Application.data_folder).each do |entry|
    if Sinatra::Application.allowed_extensions.include?(File.extname(entry))
      my_files.push(entry)
    end
  end

  
  p = Parser.new


  #we now check if all of the files are in the database already (matching the filename)
  #if they're NOT in the database, we parse and add them
  
  my_files.each do |this_file|
    if (Persistence.all(:filename => this_file.to_s).size > 0)
      #puts "File #{this_file.to_s} is already in Database :)"
    else
      puts "Processing file and saving to DB: " + this_file.to_s
      Persistence.new(p.parse(Sinatra::Application.data_folder + this_file)).save
    end
  end

  #let's get all of our tracks which are saved in the database
  #we want the newest tracks to be on top
  @my_tracks = Persistence.all(:order => [:start.desc])

  
  @total_distance = Integer(Persistence.sum(:distance) / 1000)
  @average_distance = Integer(Persistence.avg(:distance))
  @total_duration = Integer(Persistence.sum(:duration) / 3600)
  @average_duration = Integer(Persistence.avg(:duration) / 60)
  #call the template
  erb(:index)


end

get '/details/*' do

  #this is how we get the parameter in our url
  #/details/blablubb --> params[splat] == blablubb
  filename = params["splat"]
  #as this is supposed to be a filename, we check our database of the first record with this filename
  @my_item = Persistence.first(:filename => filename.to_s)
  unless @my_item.nil?
    
    
    p = Parser.new
    
    #we should be able to get this faster, maybe add this stuff to the Persistence class
    @container = p.parse(Sinatra::Application.data_folder + filename.to_s)
    

    @polyline = @container.get_embedded_map_polyline
    #we also need tha latitude/longtitude array for the borders in google maps
    @latlon = @container.get_lat_lon

    #and now to the graphs


    
    
    #************SPEED GRAPH PREPARATIONS***************
    original_speed_array = @container.get_speed_array
    my_steps = original_speed_array.size / 300
    smaller_speed_array = Array.new
    1.upto(300) do |i|
      smaller_speed_array << original_speed_array[i*my_steps]
    end

    GoogleChart::LineChart.new('500x250', "Speed (km/h)", false) do |lc|
      lc.data "Speed", smaller_speed_array , '0000ff'
      lc.show_legend = false
      #  lc.data "Altitude", altitude_array, '00ff00'
      #     lc.data "Trend 3", [6,5,4,3,2,1], 'ff0000'
      lc.axis :y, :range => [0,@container.get_speed_max], :color => 'ff00ff', :font_size => 16, :alignment => :center
      lc.axis :x, :range => [0,@container.get_duration_min], :color => '00ffff', :font_size => 16, :alignment => :center
      lc.grid :x_step => @container.get_duration_min, :y_step => @container.get_speed_avg, :length_segment => 1, :length_blank => 0

      @my_speed_url =  lc.to_url
    end

    #************ALTITUDE GRAPH PREPARATIONS***************
    original_altitude_array = @container.get_altitude_array
    minimum_altitude = original_altitude_array.min
    my_steps = original_altitude_array.size / 300
    smaller_altitude_array = Array.new
    1.upto(300) do |i|
      smaller_altitude_array << original_altitude_array[i*my_steps] - minimum_altitude
    end

    GoogleChart::LineChart.new('500x250', "Altitude  (relative to #{minimum_altitude.to_s}m)", false) do |lc|
      lc.data "Altitude", smaller_altitude_array , '0000ff'
      lc.show_legend = false
      lc.axis :y, :range => [0,@container.get_altitude_max - minimum_altitude], :color => 'ff00ff', :font_size => 16, :alignment => :center
      lc.axis :x, :range => [0,@container.get_duration_min], :color => '00ffff', :font_size => 16, :alignment => :center
      lc.grid :x_step => @container.get_duration_min, :y_step => smaller_altitude_array.max - smaller_altitude_array.min, :length_segment => 1, :length_blank => 0
      @my_altitude_url =  lc.to_url
    end

    #************HEARTRATE GRAPH PREPARATIONS***************
    original_heartrate_array = @container.get_heartrate_array
    my_steps = original_heartrate_array.size / 300
    smaller_hr_array = Array.new
    1.upto(300) do |i|
      smaller_hr_array << original_heartrate_array[i*my_steps]
    end

    GoogleChart::LineChart.new('500x250', "Heartrate  (bpm)", false) do |lc|
      lc.data "Heartrate", smaller_hr_array , '0000ff'
      lc.show_legend = false
      lc.axis :y, :range => [@container.get_heartrate_array.min,@container.get_heartrate_array.max], :color => 'ff0000', :font_size => 16, :alignment => :center
      lc.axis :x, :range => [0,@container.get_duration_min], :color => '00ffff', :font_size => 16, :alignment => :center
      lc.grid :x_step => @container.get_duration_min, :y_step => smaller_hr_array.max, :length_segment => 1, :length_blank => 0
      @my_hr_url =  lc.to_url
    end

   GoogleChart::LineChart.new('500x250', "", false) do |lc|
      lc.data "Altitude", smaller_altitude_array , '0000ff'
      lc.data "Speed", smaller_speed_array , '00ffff'
      lc.data "Heartrate", smaller_hr_array , 'ff00ff'
      lc.show_legend = false
      lc.axis :y, :range => [@container.get_heartrate_array.min,@container.get_heartrate_array.max], :color => 'ff0000', :font_size => 16, :alignment => :center
      lc.axis :x, :range => [0,@container.get_duration_min], :color => '00ffff', :font_size => 16, :alignment => :center
      lc.grid :x_step => @container.get_duration_min, :y_step => smaller_hr_array.max, :length_segment => 1, :length_blank => 0
      @my_combined_url =  lc.to_url
    end




  end

  if @my_item.nil?
    #appartenly the file in question isn't available... --> error message
    erb("Not found, sorry")
  else
    #and now let's render the template (details.erb)
    erb(:details)
  end

end

get '/embed/last' do
  @my_tracks = Persistence.first(:order => [:start.desc])
  "Last run:<br/>" + @my_tracks.start.strftime("%d.%m.%Y - %H:%M") + "<br/>" + @my_tracks.distance.to_i.to_s + " m in " + (@my_tracks.duration / 60).to_i.to_s + " min"
end


get '/delete/*' do

  #this is how we get the parameter in our url
  #/details/blablubb --> params[splat] == blablubb
  @filename = params["splat"]
  erb (:delete)
end


post '/delete/*' do
  output = ""
  if (params[:admin_pass].to_s == Sinatra::Application.admin_pass)
    deleted = Persistence.first(:filename => params[:filename].to_s).destroy
    if (deleted)
      output << "Deleted database entry<br/>"
      #if the deleting in the database went fine, we might as well delete the file...
      my_file = Sinatra::Application.data_folder.to_s + params[:filename].to_s
      if File.exists?(my_file)
        File.delete(my_file)
        output << "Deleted File!<br/>"
      else
        output << "File not found!<br/>"
      end
    else
      output << "error while deleting<br/>"
    end
  else
    output << "wrong password!<br/>"
  end
  erb (output + 'Done<br/><a href="/">back</a>')

end

get '/upload' do
  erb :upload
end

post '/upload' do
  output = ""
  if (params[:admin_pass].to_s == Sinatra::Application.admin_pass)
    FileUtils.mv(params[:uploaded_data][:tempfile].path, Sinatra::Application.data_folder + params[:uploaded_data][:filename])
    output << "finished upload<br/>"
  else
    output << "wrong password!<br/>"
  end
  erb (output + 'Done<br/><a href="/">back</a>')
end
