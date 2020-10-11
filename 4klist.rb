# 2020-08-27
#
# This script takes the list from https://thedigitalbits.com/columns/the-4k-uhd-release-list/4k-uhd-list-01
# and outputs CSV to stdout.
#
# Current spreadsheet: https://docs.google.com/spreadsheets/d/1XgBqUDMwN-_CvbQssa7KVY_j56kimrgfePAH7i3dStM/edit#gid=0
#
# Linked on forum: https://www.makemkv.com/forum/viewtopic.php?f=12&t=22992

require 'mechanize'

OVERRIDES = {
  'Dolittle' => { :dolby_vision => true }
}

puts "Title,Reference Disc,Standout Disc,Native 4k,Dolby Vision,HDR10+,Imax Enhanced,60 FPS,Dolby Atmos,DTS:X,Release Date,Studio"

studio = ''

def parseList(studio, list)
  studio = studio.gsub(',', '')
  list.search('li').each do |item|
    features = ''
    reference = false
    standout = false
    native4k = false
    dolby_vision = false
    hdr10plus = false
    imax = false
    dolby_atmos = false
    dtsx = false
    fps60 = false

    title = item.search('strong').first.content

    if match = item.content.match(/\d+\/\d+\/\d+/)
      date = match
    elsif match = item.content.match(/TBA( \d{4})?/)
      date = match
    else
      date = '""'
    end

    if match = item.content.match(/– ([\w,+\-()& ]*)$/)
      features = match[1].split(',').collect { |e| e.strip }.join('|')
      native4k = true     if features.include? 'N4K'
      dolby_vision = true if features.include? 'DV'
      hdr10plus = true    if features.include? '10+'
      imax = true         if features.include? 'IMAX-E'
      dolby_atmos = true  if features.include? 'DA'
      dtsx = true         if features.include? 'X'
      fps60 = true        if features.include? '60'
    end

    # Reference/standout check
    if title.match(/\*\*/)
      title = title.gsub('**', '')
      reference = true
    elsif title.match(/\*/)
      title = title.gsub('*', '')
      standout = true
    end

    # Overrides for incorrect parsing or missing features
    if override = OVERRIDES[title]
      native4k     = override[:native4k]     || native4k
      dolby_vision = override[:dolby_vision] || dolby_vision
      hdr10plus    = override[:hdr10plus]    || hdr10plus
      imax         = override[:imax]         || imax
      dolby_atmos  = override[:dolby_atmos]  || dolby_atmos
      dtsx         = override[:dtsx]         || dtsx
      fps60        = override[:fps60]        || fps60
      reference    = override[:reference]    || reference
      standout     = override[:standout]     || standout
    end

    csv = ["\"#{title}\"", reference, standout, native4k, dolby_vision, hdr10plus, imax, fps60, dolby_atmos, dtsx, date, studio].join(',')

    puts csv
  end
end

agent = Mechanize.new do |agent|
  agent.user_agent_alias = 'Mac Safari'
end

agent.get('https://thedigitalbits.com/columns/the-4k-uhd-release-list/4k-uhd-list-01') do |page|
  content = page.search('#k2Container .itemFullText').first.children
  content.each do |entry|
    if entry.is_a? Nokogiri::XML::Element
      if entry.name == 'h4'
        studio = entry.content
      elsif entry.name == 'ul'
        parseList(studio, entry)
      end
    end
  end
end

