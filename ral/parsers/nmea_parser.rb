def parse_nmea(filehandle)
      container = Container.new
      time = 0
      date = 0
      counter = 0
      
      # First of all, find the date! After we found it, we break
      # the operation, so the actuall data can be parsed
      filehandle.each_line do |line|    
        # $GPRMC line contains the date
        if date == 0 && line.split(',')[0] == "$GPRMC"
            date = line.split(',')[9]
            date = transformDate(date)
            break
        end
      end #do
        
      filehandle.each_line do |line|
        #  GPGGA line contains all necessary data except of the date
        if line.split(',')[0] == "$GPGGA"
          time = (line.split(',')[1]).split('.')[0]
          time = transformTime(time)
          require "time"
          temp_stamp = Timestamp.new(Time.parse(date+"T"+time+"Z")) #We convert our time string to an actual time object which is passed to the timestamp
          #container.new_timestamp(date+"T"+time+"Z")
          temp_stamp.set_data(:latitude, transformCoord(line.split(',')[2]))
          temp_stamp.set_data(:longitude, transformCoord(line.split(',')[4]))
          temp_stamp.set_data(:altitude, Float(line.split(',')[9]))
          container._timestamps[(temp_stamp.get_data(:time))]=temp_stamp
       # puts transformCoord(line.split(',')[2])+" - "+transformCoord(line.split(',')[4])+" - "+line.split(',')[9]
          counter+=1           
        end    
        
      end #do
      container
    end
    
    def transformDate(date)
      # Merge the date to correct target format
            temp1 = date[0..1]
            temp2 = date[2..3]
            temp3 = date[4..5]
            
            # I know,  prefixing a 20 is lazy, but nobody will use that application in 21XX :-P
            date = "20"+temp3+"-"+temp2+"-"+temp1
    end
          
    # Tramsforms NMEA time format (hhmmss) to our time format (hh:mm:ss)
    def transformTime(time)
      temp1 = time[0..1]
      temp2 = time[2..3]
      temp3 = time[4..5]
      time = temp1+":"+temp2+":"+temp3
      
    end
    
    # Transforms NMEA coordinate format to our format
    def transformCoord(coord)
        dotat = coord.index('.') 
        tmp1 = coord[dotat-1]
        tmp2  = coord[dotat-2]
        
        coord[dotat-2] = "."
        coord[dotat-1] = tmp2
        coord[dotat] = tmp1
    
        return coord.to_f     
    end
    