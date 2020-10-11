# 2020-08-27
#
# This script takes the list from https://thedigitalbits.com/columns/the-4k-uhd-release-list/4k-uhd-list-01
# and outputs CSV to stdout.
#
# Current spreadsheet: https://docs.google.com/spreadsheets/d/1XgBqUDMwN-_CvbQssa7KVY_j56kimrgfePAH7i3dStM/edit#gid=0
#
# Linked on forum: https://www.makemkv.com/forum/viewtopic.php?f=12&t=22992

require_relative './parser'

source = if ENV['DEBUG']
  "file:///#{__dir__}/dump.html"
else
  'https://thedigitalbits.com/columns/the-4k-uhd-release-list/4k-uhd-list-01'
end

overrides = {
  'Dolittle' => { dolby_vision: true }
}

parser = Parser.new(source, overrides)
data = parser.convert

if ENV['FILE']
  File.open(ENV['FILE'], 'w') do |file|
    file.puts data.to_csv
  end
  puts "File written: #{ENV['FILE']}"
else
  puts data.to_csv
end
