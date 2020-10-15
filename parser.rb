require 'mechanize'

class Parser

  attr_reader :source, :rows, :header, :overrides, :skips

  def initialize(source, options = {})
    @source = source
    @rows = []
    @header = "Title,Reference Disc,Standout Disc,Native 4k,Dolby Vision,HDR10+,Imax Enhanced,60 FPS,Dolby Atmos,DTS:X,Release Date,Studio"
    @overrides = options[:overrides]
    @skips = options[:skips]
  end

  def convert
    studio = ''

    agent.get(source) do |page|
      content = page.search('#k2Container .itemFullText').first.children
      content.each do |entry|
        if entry.is_a? Nokogiri::XML::Element
          if entry.name == 'h4'
            studio = entry.content
          elsif entry.name == 'ul'
            @rows << parse_list(studio, entry)
          end
        end
      end
    end

    @rows = rows.flatten

    return self
  rescue => e
    puts "ERROR: #{e.message}\n#{e.backtrace}"
    false
  end

  def to_csv
    [header, rows.sort].flatten
  end

  private def agent
    @agent ||= Mechanize.new do |agent|
      agent.user_agent_alias = 'Mac Safari'
    end
  end

  private def parse_list(studio, list)
    studio = studio.gsub(',', '')

    list.search('li').collect do |item|
      title, reference, standout = parse_title(item)
      date = parse_date(item)
      features = parse_features(title, item)

      if title
        [
          "\"#{title}\"",
          reference,
          standout,
          features[:native4k],
          features[:dolby_vision],
          features[:hdr10plus],
          features[:imax],
          features[:fps60],
          features[:dolby_atmos],
          features[:dtsx],
          date,
          studio
        ].join(',')
      end
    end.compact
  end

  private def parse_title(node)
    title = node.search('strong').first.content
    reference = false
    standout = false

    if title.match(/\*\*/)
      title = title.gsub('**', '')
      reference = true
    elsif title.match(/\*/)
      title = title.gsub('*', '')
      standout = true
    end

    title.gsub!('’', "'")

    # Move "The" to the end of the title
    if title.match(/^The +/)
      title.gsub!(/^The +/, '')
      # Deal with titles have a colon or parethesis, put The before that character,
      # otherwise add to the end of the string
      title.gsub!(/^(.*?)(:| \(|$)/, '\1, The\2')
    end

    [title, reference, standout] unless skip_title?(title)
  end

  private def parse_date(node)
    if match = node.content.match(/\d+\/\d+\/\d+/)
      date = match
    elsif match = node.content.match(/TBA( \d{4})?/)
      date = match
    else
      date = '""'
    end
  end

  private def parse_features(title, item)
    feat = {
      native4k: false,
      dolby_vision: false,
      hdr10plus: false,
      imax: false,
      dolby_atmos: false,
      dtsx: false,
      fps60: false
    }

    if match = item.content.match(/– ([\w,+\-()& ]*)$/)
      features = match[1].split(',').collect { |e| e.strip }.join('|')
      feat[:native4k] = true     if features.include? 'N4K'
      feat[:dolby_vision] = true if features.include? 'DV'
      feat[:hdr10plus] = true    if features.include? '10+'
      feat[:imax] = true         if features.include? 'IMAX-E'
      feat[:dolby_atmos] = true  if features.include? 'DA'
      feat[:dtsx] = true         if features.include? 'X'
      feat[:fps60] = true        if features.include? '60'
    end

    # Overrides for incorrect parsing or missing features
    feat.merge!(overrides[title]) if overrides[title]

    feat
  end

  private def skip_title?(title)
    skips.include?(title)
  end

end
