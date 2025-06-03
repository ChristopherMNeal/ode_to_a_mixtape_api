# frozen_string_literal: true

require 'date'
require_relative 'scrapers/broadcast_index_scraper'
require_relative 'scrapers/broadcast_page_scraper'
require_relative 'scrapers/broadcast_metadata_extractor'
require_relative 'scrapers/playlist_parser'

# Main coordinator for the broadcast scraping process.
#
# This class orchestrates the scraping process using specialized component classes:
# - BroadcastIndexScraper: Handles scraping the broadcast index pages
# - BroadcastPageScraper: Handles scraping individual broadcast pages
# - BroadcastMetadataExtractor: Extracts metadata about broadcasts (air times, DJ info)
# - PlaylistParser: Creates and updates playlist records
#
# Usage: ScrapeBroadcasts.new.call(broadcast, start_date, end_date)
# start_date and end_date are inclusive. If you want to scrape a single broadcast, set both to the broadcast date.
# Start date and end date are optional.
# If no start date is provided, the most recent playlist date in the database is used.
# If no playlists are in the database, the start date is set to 1901-12-12, the date of the first radio broadcast.
# If no end date is provided, all broadcasts after the start date are scraped.
class ScrapeBroadcasts
  attr_accessor :throttle_secs,
                :broadcast,
                :start_date,
                :end_date

  def initialize(broadcast, start_date = nil, end_date = nil, throttle_secs: 0)
    @throttle_secs = throttle_secs || 0
    @broadcast = broadcast
    @start_date = get_start_date(start_date)
    @end_date = end_date
  end

  def call
    scrape_broadcasts
  end

  # Accessor methods for the component classes
  def index_scraper
    @index_scraper ||= BroadcastIndexScraper.new(broadcast, throttle_secs)
  end

  def page_scraper
    @page_scraper ||= BroadcastPageScraper.new(broadcast, throttle_secs)
  end

  def metadata_extractor
    @metadata_extractor ||= BroadcastMetadataExtractor.new(broadcast)
  end

  def playlist_parser
    @playlist_parser ||= PlaylistParser.new(broadcast)
  end

  # Methods for backward compatibility with tests
  def find_start_date_page_number(base_url, broadcast_name_for_url)
    index_scraper.find_start_date_page_number(broadcast_name_for_url, start_date)
  end

  def open_broadcasts_index_page(base_url, broadcast_name_for_url, page_number)
    index_scraper.open_broadcasts_index_page(broadcast_name_for_url, page_number)
  end

  private

  def scrape_broadcasts
    scrape_logger "Scraping broadcast: #{broadcast.title}, start date: #{start_date}, end date: #{end_date || 'none'}"

    base_url = broadcast.station.base_url
    broadcast_name_for_url = broadcast.url.split('/').last

    # First page to update broadcast metadata
    first_page = index_scraper.open_broadcasts_index_page(broadcast_name_for_url, 1)
    metadata_extractor.update_broadcast_details(first_page) if first_page

    # Find the starting page number based on requested start date
    page_number = index_scraper.find_start_date_page_number(broadcast_name_for_url, start_date)

    # Process each page of broadcasts, starting from the found page
    loop do
      # Get the page
      paginated_broadcast_index = index_scraper.open_broadcasts_index_page(broadcast_name_for_url, page_number)
      break unless paginated_broadcast_index

      scrape_logger "Loaded paginated broadcast page #{page_number}"

      # Get each broadcast on the page
      broadcast_divs = paginated_broadcast_index.css('div.broadcasts-container div.broadcast')

      # Reverse the order of the broadcasts so we can start from the oldest playlist
      broadcast_divs.reverse.each do |broadcast_div|
        # Extract broadcast details
        broadcast_date = index_scraper.parse_broadcast_date(broadcast_div)

        if end_date && broadcast_date > end_date
          scrape_logger "Broadcast from #{broadcast_date} is after the end date #{end_date}, stopping"
          break
        elsif broadcast_date <= start_date
          scrape_logger "Broadcast from #{broadcast_date} is before the start date #{start_date}, skipping"
          next
        end

        parsed_url = broadcast_div.css('div.title a').attribute('href').value
        broadcast_show_url = base_url + parsed_url
        title = broadcast_div.css('div.title a').text.strip

        scrape_logger "  Processing: #{broadcast.title}: #{broadcast_date.strftime('%I:%M%p, %m-%d-%Y')} " \
                      "- #{title} from #{parsed_url}"

        # Get and process the broadcast show page
        broadcast_show_page = page_scraper.open_url(broadcast_show_url)
        next unless broadcast_show_page

        # Extract track data
        tracks_hash_array = page_scraper.parse_tracks(broadcast_show_page)

        # Create or update the playlist
        ActiveRecord::Base.transaction(requires_new: true) do
          playlist = playlist_parser.find_or_create_playlist(
            broadcast_date, title, broadcast_show_url, broadcast_show_page, tracks_hash_array
          )
          playlist.create_records_from_tracks_hash
        end
      end

      # Move to the previous page (pages are in reverse chronological order)
      break if page_number == 1

      page_number -= 1
    end

    # Update broadcast end time and last scraped timestamp
    metadata_extractor.update_air_time_end
    broadcast.update(last_scraped_at: Time.zone.now)
    scrape_logger("Finished scraping broadcast: #{broadcast.title}\n\n")
  end

  def get_start_date(start_date)
    # if no start date is provided, find the date of the most recent broadcast in the database to start from
    if start_date.is_a?(Date)
      start_date.beginning_of_day
    elsif !start_date.nil?
      Date.parse(start_date).beginning_of_day
    elsif broadcast.playlists.present?
      broadcast.playlists.maximum(:air_date)
    else
      Date.new(1901, 12, 12)
    end
  rescue DataError => e
    scrape_logger "Invalid start date: #{start_date}"
    raise e
  end

  def scrape_logger(message)
    ScrapeLogger.log(message)
  end
end
