require 'rubygems'
require 'sinatra'
require 'pstore'
require "yaml"
require 'models/gpx_file.rb'


set :persistence, PStore.new("persistence/persistence.pstore")
set :user_options, YAML::load( File.open( 'config/sharearun.yml' ) )

set :dir_list, Dir.entries("gpx").select{|item|
		case item
		when ".."
			false
			next
		when "."
			false
			next
		when !File.directory?("gpx/#{item}")
			false
			next
		else
			true
		end

	}



def insert_into_pstore(path_to_gpx)
	@pstore = options.persistence
	puts "Crunching on #{path_to_gpx}"
	category_folder = path_to_gpx.split("/")[1]
	file_name = path_to_gpx.split("/").last
	
	parsed_file = GPX_file.new(path_to_gpx)
	
	@pstore.transaction do
		# ensure that an index has been created...
		@pstore[category_folder] ||= Array.new
		@pstore[path_to_gpx] = parsed_file
		#add newly parsed file to the index
		@pstore[category_folder].push(path_to_gpx)
	end
	puts "Analyzed and inserted #{path_to_gpx}"
end


get '/' do
	@dir_list = options.dir_list
	erb(:index)
end



get '/category/:foldername' do
	@dir_list = options.dir_list
	throw :halt, [404, "This category does not exist!"] unless @dir_list.include?(params[:foldername])
	@pstore = options.persistence

	@file_list = Dir.glob("gpx/#{params[:foldername]}/*.gpx").sort.reverse
	
	files_to_insert = Array.new	

	#detect new files
	@pstore.transaction(true) do
		@file_list.each do |item|
			if @pstore[params[:foldername]].nil?
				files_to_insert << item
				next
			elsif !(@pstore[params[:foldername]].include?(item))
				files_to_insert << item
			end #if
		end #do
	end #do
	#insert new files
	files_to_insert.each do |gpxfile|
		insert_into_pstore(gpxfile)
	end


	#update total stats and get file_list for view
	@view_list = Array.new
	@stats = Hash.new
	@stats["total_distance"] = 0.0
	@stats["total_duration"] = 0.0
	@pstore.transaction do
		@pstore[params[:foldername]].each do |gpxfile|
			@stats["total_distance"] += @pstore[gpxfile].distance
			@stats["total_duration"] += @pstore[gpxfile].duration
			@view_list << @pstore[gpxfile]
		end unless @pstore[params[:foldername]].nil?
	end

	@view_list.sort!{|item1, item2| item2.time_start <=> item1.time_start}

	erb(:category)
end



get '/details/*' do

	@dir_list = options.dir_list

	@pstore = options.persistence
	@google_maps_key = options.user_options["google_maps_key"]
	
	@file_data = nil
	full_path = params[:splat].join("/")
	throw :halt, [404, "File #{full_path} does not exist!"] unless File.exist?(full_path)
	@pstore.transaction(true) {@file_data = @pstore[full_path]}

	if @file_data.nil?		
	#it's not in there yet --> put it in there
		insert_into_pstore(full_path)
		@pstore.transaction(true) {@file_data = @pstore[full_path]}
	end
		
	erb(:details)
end


