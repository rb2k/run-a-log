$LOAD_PATH << "./ral/model"
$LOAD_PATH << "./ral/parsers"
$LOAD_PATH << "./ral/"
$LOAD_PATH << "./lib/"

require "rubygems"
require "Tester"
my_tester = Tester.new("sample_data/GPS_short.kml")
my_tester.start