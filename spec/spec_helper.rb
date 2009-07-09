# require 'spec/autorun'
require 'erb'
$LOAD_PATH << File.join(File.dirname(__FILE__), '..')
ENV['COUCH'] = "http://127.0.0.1:5984/test_detexify"

require 'symbol'