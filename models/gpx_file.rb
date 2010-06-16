class GPX_file
	require "hpricot"
	require "time"
	require "./lib/geo.rb"
	require "./lib/gmap_polyline_encoder.rb"
	attr_accessor :filename, :speed_avg, :elevation_min, :elevation_max, :polyline, :time_start, :time_end, :duration, :distance, :polyline, :startingpoint

	def initialize(path_to_file)
		@filename = path_to_file
		self.parse()
	end

	def parse
		 doc = open(@filename) { |f| Hpricot(f) }

		#***********TIMES+DURATIONS***********
		@time_start = Time.parse(doc.search("//trkpt/time").first.inner_text)		
		@time_end = Time.parse(doc.search("//trkpt/time").last.inner_text)
		@duration = (@time_end - @time_start)
		
		#***********ELEVATIONS***********
		elevations = doc.search("//ele").map{|ele| ele.inner_text.to_f}
		@elevation_min = elevations.min
		@elevation_max = elevations.max

		trackpoints = Array.new
		doc.search("//trkpt").each do |trackpoint|
		lat = trackpoint["lat"].to_f
		lon = trackpoint["lon"].to_f
		time = Time.parse(trackpoint.at("time").inner_text)
		trackpoints << [lat, lon, time]
		end
		@startingpoint = [trackpoints.first[0], trackpoints.first[1]]

		geocoder = Geo.new
		speeds = Array.new
		@distance = 0.0
		#***********DISTANCE+SPEEDS***********
		0.upto((trackpoints.size) -1) do |index|
			next if index == 0
			current_dist_m = geocoder.distance_in_m(trackpoints[index][0], trackpoints[index][1], trackpoints[index-1][0], trackpoints[index-1][1])
			@distance += current_dist_m
			current_time_diff_ms = trackpoints[index][2].to_f - trackpoints[index-1][2].to_f
			current_dist_km = current_dist_m / 1000
			current_time_diff_h =  current_time_diff_ms / 100.0 / 60.0
			current_speed_kmh = current_dist_km / current_time_diff_h

			speeds << current_speed_kmh
		end

		@speed_avg = (@distance / 1000) / (@duration / 3600)
		@distance = @distance.floor

		#***********POLYLINE***********
		encoder = GMapPolylineEncoder.new()
		data = trackpoints.map{|tp| [tp[0], tp[1]] }
   		result = encoder.encode( data )
		javascript  = ""
		   javascript << "  var myLine = new GPolyline.fromEncoded({\n"
		   javascript << "     color: \"#FF0000\",\n"
		   javascript << "     weight: 10,\n"
		   javascript << "     opacity: 0.5,\n"
		   javascript << "     zoomFactor: #{result[:zoomFactor]},\n"
		   javascript << "     numLevels: #{result[:numLevels]},\n"
		   javascript << "     points: \"#{result[:points]}\",\n"
		   javascript << "     levels: \"#{result[:levels]}\"\n"
		   javascript << "  });"
		@polyline = javascript

	end



end
