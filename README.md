# 4klist

Dumps the list of all 4k UHD disc releases from https://thedigitalbits.com/columns/the-4k-uhd-release-list/4k-uhd-list-01 to CSV format.

The resulting list is shared here: https://docs.google.com/spreadsheets/d/1XgBqUDMwN-_CvbQssa7KVY_j56kimrgfePAH7i3dStM/edit#gid=1830409724

## Usage

Clone this repo, install depencencies and execute with Ruby:

    git clone https://github.com/cannikin/4klist.git
    cd 4klist
    bundle install
    ruby 4klist.rb

The CSV output is sent to stdout. Copy and paste to your spreadsheet software of choice!