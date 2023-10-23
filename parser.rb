require 'dotenv/load'
require 'mechanize'
require 'vacuum'

class Parser

  attr_reader :source, :rows, :header, :overrides, :skips

  def initialize(source, options = {})
    @source = source
    @rows = []
    @header = "Title,Reference Disc,Standout Disc,Native 4k,Dolby Vision,HDR10+,Imax Enhanced,60 FPS,Dolby Atmos,DTS:X,Release Date,Studio,Review,Buy US,Buy UK"
    @overrides = options[:overrides]
    @skips = options[:skips]
  end

  def convert
    studio = ''

    agent.redirect_ok = true
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
      store_us, store_uk, review = parse_links(item)
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
          studio,
          review ? %Q[=HYPERLINK("#{review}";"Review")] : '',
          store_us ? %Q[=HYPERLINK("#{store_us}";"#{store_us.split('/')[2]}")] : '',
          store_uk ? %Q[=HYPERLINK("#{store_uk}";"#{store_uk.split('/')[2]}")] : '',
        ].join(',')
      end
    end.compact
  end

  private def parse_title(node)
    title = node.search('strong').first.content.strip
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

    puts "Found #{title}"

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

  private def parse_links(node)
    store_us, store_uk, review = nil

    node.search('a').each do |link|
      if link.content.match 'US' and link['href']
        if link['href'].match 'amzn.to'
          store_us = parse_amazon_short_link(link)
        elsif link['href'].match 'amazon.com/exec/obidos'
          store_us = parse_amazon_long_link(link)
        else
          store_us = link['href']
        end
      elsif link.content.match 'UK'
        store_uk = link['href']
      elsif link.content.match 'REVIEW'
        review = "https://thedigitalbits.com#{link['href']}"
      end
    end

    return store_us, store_uk, review
  end

  private def parse_amazon_short_link(link)
    agent.redirect_ok = false
    page = agent.get(link['href'])

    if redirect = page.header['location']
      parts = redirect.split('/')[0..5]
      return parts.join('/') + '?tag=camerontec014-20'
    else
      puts "ERROR: No redirect found for #{node.content}"
      puts "Link: #{link} page.header['location']: #{page.header['location']}"
      return link['href']
    end
  end

  private def parse_amazon_long_link(link)
    return link['href'].gsub(/thedigitalbits-20/, ENV['AMAZON_ASSOCIATE_TAG'])
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

  # Not working yet, need Amazon to get me access to the Product Advertising API
  private def short_link(product_id)
    response = amazon_client.get_items(
      item_ids: [product_id],
      response_group: 'ItemAttributes',
    )

    puts response

  end

  private def amazon_client
    @amazon_client ||= Vacuum.new(marketplace: 'US',
                     access_key: ENV['AMAZON_KEY'],
                     secret_key: ENV['AMAZON_SECRET_KEY'],
                     partner_tag: ENV['AMAZON_ASSOCIATE_TAG'])
  end
end
