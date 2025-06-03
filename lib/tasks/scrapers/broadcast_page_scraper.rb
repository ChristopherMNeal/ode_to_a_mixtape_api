# frozen_string_literal: true

require 'open-uri'
require 'nokogiri'

# Responsible for scraping individual broadcast pages
class BroadcastPageScraper
  attr_reader :broadcast, :throttle_secs

  def initialize(broadcast, throttle_secs = 0)
    @broadcast = broadcast
    @throttle_secs = throttle_secs || 0
  end

  def open_url(url)
    if throttle_secs.positive?
      scrape_logger "Throttling request for #{throttle_secs} seconds"
      sleep(throttle_secs)
    end
    Nokogiri::HTML(URI.open(url).set_encoding('utf-8').read.encode('UTF-8')) # rubocop:disable Security/Open
  rescue OpenURI::HTTPError => e
    scrape_logger("Error opening page #{url}: #{e.message}")
    nil
  end

  def parse_tracks(broadcast_show_page)
    date = broadcast_show_page.css('div.date').text.split(',').last.strip
    broadcast_show_page.css('div.creek-playlist li.creek-track').map.with_index do |track, index|
      song_time_string = track.css('span.creek-track-time').text.upcase
      date_time_string = "#{date}, #{song_time_string}"
      expected_format = /\A\d{1,2}-\d{1,2}-\d{4}, \d{1,2}:\d{2}(AM|PM)\z/

      begin
        if date_time_string.match?(expected_format)
          song_datetime = DateTime.strptime(date_time_string, '%m-%d-%Y, %I:%M%p')
        else
          puts date_time_string # rubocop:disable Rails/Output
          raise ArgumentError, "Date string '#{date_time_string}' does not match the expected format."
        end
      rescue ArgumentError => e
        scrape_logger "Failed to parse broadcast date from #{date_time_string}: #{e.message}"
      end

      {
        track_number: index + 1,
        time_string: song_time_string,
        start_time: song_datetime,
        title: track.css('span.creek-track-title').text.strip,
        artist: track.css('span.creek-track-artist').text.strip,
        album: track.css('span.creek-track-album').text.strip,
        label: track.css('span.creek-track-label').text.strip
      }
    end
  end

  def process_broadcast_download_urls(broadcast_show_page)
    broadcast_show_page.css('a.player').pluck('href')
  end

  private

  def scrape_logger(message)
    ScrapeLogger.log(message)
  end
end
