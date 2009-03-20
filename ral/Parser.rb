require "Container.rb"

class Parser
  def parse(file)
    fileHandle = File.open(file)
    #creating a new container, this is what out parsers will fill
    #there might be a call by value/reference problem... closures could help
    container = Container.new
    
    #detect the thile extention ...
    extension = file.split('.').last
    
    #... and act accordingly
    case extension
      when "nmea"
        #puts "Processing NMEA File: Start"
        container = nmea(fileHandle)
        #puts "Processing NMEA File: Done"
    
      when "gpx"
        #puts "Processing gpx File"
        container = gpx(fileHandle)
      
      when "kml"
        #puts "Processing KML File"
        container = kml(fileHandle)
        
      else
        puts "Can't deal with file extention: " + extension
    end
    
    fileHandle.close  
    GC.start #this might help in windows... windows doesn't always give em right back

    #adding our filename
    container.set_data(:filename, file.split("/").last)
    container #will our parse method return a filled container?
    
  end
    
  # Following methods will parse the specific file  
  # Following container must not called from other classes
  
  # GPX File parser
  def gpx(filehandle)
    require "gpx_parser.rb"
    
    #will return a container
    parse_gpx(filehandle)
  end
  
  # KML File parser  
  def kml(filehandle)  
    require "kml_parser.rb"
    parse_kml(filehandle)
    
  end
  
  # NMEA File parser
  def nmea(filehandle)
    require "nmea_parser.rb"
    parse_nmea(filehandle)
     
   end
   
   
end
