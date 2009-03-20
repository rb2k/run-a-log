$LOAD_PATH << "./ral/model"
$LOAD_PATH << "./ral/parsers"
$LOAD_PATH << "./ral/"
$LOAD_PATH << "./lib/"

require "rubygems"
require "Tester"
my_tester = Tester.new("sample_data/2008-09-07_17-36-57.gpx")
my_tester.start
