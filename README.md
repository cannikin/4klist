# 4klist

Dumps the list of all 4k UHD disc releases from https://thedigitalbits.com/columns/the-4k-uhd-release-list/4k-uhd-list-01 to CSV format.

The resulting list is shared here: https://docs.google.com/spreadsheets/d/1XgBqUDMwN-_CvbQssa7KVY_j56kimrgfePAH7i3dStM

## Usage

Clone this repo, install depencencies and execute with Ruby:

    git clone https://github.com/cannikin/4klist.git
    cd 4klist
    bundle install
    ruby 4klist.rb

By default the CSV output is sent to stdout. Copy and paste to your spreadsheet software of choice!
To output to a file instead, set a `FILE` ENV var with a path to the output:

    FILE=/Users/rob/Desktop/4k-releases.csv ruby 4klist.rb

## Dump Files

The `dump.html` file is the HTML source of thedigitalbits.com listing page and is meant to be used
to test changes to the script without actually requesting the live site over and over again.

Run the script with `DEBUG=1` set and it will use the dump file instead:

    DEBUG=1 ruby 4klist.rb

## Changelog

2020-10-11

* Moved logic to class-based structure
* Title titles starting with "The" and move them to the end of the title, ie. "The Meg" -> "Meg, The"
