# frozen_string_literal: true

require 'open-uri'
require 'nokogiri'

# Responsible for scraping the broadcast index pages
class BroadcastIndexScraper
  attr_reader :broadcast, :station, :base_url, :throttle_secs

  def initialize(broadcast, throttle_secs = 0)
    @broadcast = broadcast
    @station = broadcast.station
    @base_url = station.base_url
    @throttle_secs = throttle_secs || 0
  end

  def open_broadcasts_index_page(broadcast_name_for_url, page_number)
    # This should minimize duplicate requests made while searching for the last available page number
    @cached_broadcasts ||= {}
    @cached_broadcasts[page_number] ||=
      open_url(
        "#{base_url}/programs/#{broadcast_name_for_url}/page:#{page_number}?url=broadcasts%2F#{broadcast_name_for_url}"
      )
  rescue OpenURI::HTTPError => e
    scrape_logger "Error opening broadcasts index page for #{broadcast.title} on page #{page_number}: #{e.message}"
    nil
  rescue StandardError => e
    scrape_logger "Unexpected error opening broadcasts index page for #{broadcast.title} on page #{page_number}: #{e.message}"
    nil
  end

  def find_start_date_page_number(broadcast_name_for_url, start_date)
    page_number = 1
    previous_page_start_date = Time.zone.today.end_of_day

    loop do
      paginated_broadcast_index = open_broadcasts_index_page(broadcast_name_for_url, page_number)
      unless paginated_broadcast_index
        scrape_logger "Failed to load paginated broadcast index page for #{broadcast.title} on page #{page_number}"
        break
      end

      broadcast_dates = fetch_broadcast_dates(paginated_broadcast_index)
      break if broadcast_dates.empty?

      min_date = broadcast_dates.min.beginning_of_day
      max_date = previous_page_start_date

      scrape_logger "Page #{page_number}: #{min_date} - #{max_date}"
      scrape_logger "Start date: #{start_date}"

      if start_date.between?(min_date, max_date)
        break
      elsif start_date < min_date
        break unless next_page_available?(paginated_broadcast_index)

        previous_page_start_date = min_date
        page_number += 1
      else
        scrape_logger "Something went wrong while searching for the start date page number for #{broadcast.title}"
      end
    end
    page_number
  end

  def fetch_broadcast_dates(paginated_broadcast_index)
    paginated_broadcast_index.css('div.broadcasts-container div.broadcast').map do |broadcast_div|
      parse_broadcast_date(broadcast_div)
    end
  end

  def parse_broadcast_date(broadcast_div)
    DateTime.strptime(broadcast_div.css('div.date').text, '%I:%M%p, %m-%d-%Y')
  end

  def next_page_available?(paginated_broadcast_index)
    !paginated_broadcast_index.css('div.pagination-container div.pagination-inner span.next a').empty?
  end

  def extract_broadcast_details(broadcast_div)
    broadcast_date = parse_broadcast_date(broadcast_div)
    parsed_url = broadcast_div.css('div.title a').attribute('href').value
    broadcast_show_url = base_url + parsed_url
    title = broadcast_div.css('div.title a').text.strip

    {
      date: broadcast_date,
      url: broadcast_show_url,
      title:,
      parsed_url:
    }
  end

  def open_url(url)
    if throttle_secs.positive?
      scrape_logger "Throttling request for #{throttle_secs} seconds"
      sleep(throttle_secs)
    end
    # Open the URL, set the stream's encoding to UTF-8, read the content,
    # ensure it's encoded in UTF-8, and parse with Nokogiri
    Nokogiri::HTML(URI.open(url).set_encoding('utf-8').read.encode('UTF-8')) # rubocop:disable Security/Open
  rescue OpenURI::HTTPError => e
    # Log any HTTP errors encountered during the fetch
    scrape_logger("Error opening page #{url}: #{e.message}")
    nil
  end

  private

  def scrape_logger(message)
    ScrapeLogger.log(message)
  end
end
