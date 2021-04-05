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
  'Blade' => { dolby_vision: false },
  'Collateral' => { dolby_vision: true },
  'Mulan (1998)' => { native4k: true, dolby_atmos: true },
  'Mulan (2020)' => { native4k: true, dolby_atmos: true },
  'Warrior' => { dolby_vision: false },
}

skips = [
  "Criterion's first 4K title could be announced in 2021"
]

parser = Parser.new(source, overrides: overrides, skips: skips)
data = parser.convert

filename = "dumps/#{Time.now.strftime('%Y-%m-%d')}.csv"

# Write output to stdout
puts data.to_csv

# Write output to file
File.open(filename, 'w') do |file|
  file.puts data.to_csv
end
puts "\n\nWrote file: #{filename}"
