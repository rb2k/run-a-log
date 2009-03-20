$LOAD_PATH << "./ral/model"
$LOAD_PATH << "./ral/parsers"
$LOAD_PATH << "./ral/"
$LOAD_PATH << "./lib/"

require "rubygems"
require "Tester"
my_tester = Tester.new("sample_data/00004_20081209.nmea")
my_tester.start