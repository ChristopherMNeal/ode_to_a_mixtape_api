# frozen_string_literal: true

require 'open-uri'
require 'nokogiri'

class ScrapeBroadcastTitles
  def call(station) # rubocop:disable Metrics
    scrape_logger("Scraping broadcast titles for #{station.name}")
    station_broadcast_index_url = station.broadcasts_index_url
    titles_urls_hashes = fetch_all_broadcast_titles(station_broadcast_index_url)
    titles_urls_hashes.each do |titles_urls_hash|
      title = titles_urls_hash[:title]
      url = "#{station.base_url}#{titles_urls_hash[:url]}"
      ActiveRecord::Base.transaction do
        broadcast = Broadcast.where(station:, url:).first_or_initialize
        broadcast.update_broadcast_title(title, url)
        broadcast.save!
        scrape_logger "Updated broadcast: #{broadcast.title}"
      rescue StandardError => e
        scrape_logger("Error updating broadcast: #{e.message}")
      end
    end
  end

  private

  def fetch_all_broadcast_titles(station_broadcast_index_url)
    html_content = URI.open(station_broadcast_index_url) # rubocop:disable Security/Open
    html_content.set_encoding('utf-8') # Ensure content is treated as UTF-8

    doc = Nokogiri::HTML(html_content.read.encode('UTF-8'))

    doc.css('div.title a').map do |a_element|
      { title: a_element.text.scrub.encode('utf-8').strip,
        url: a_element['href'].strip }
    end
  end

  def scrape_logger(message)
    ScrapeLogger.log(message)
  end
end
