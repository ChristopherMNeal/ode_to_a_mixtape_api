# frozen_string_literal: true

require 'open-uri'
require 'nokogiri'

class ScrapeBroadcastTitles
  def call(station)
    station_broadcast_index_url = station.broadcasts_index_url
    # titles_urls_hashes = fetch_all_broadcast_titles(station_broadcast_index_url)
    titles_urls_hashes = [{ title: ' // Melted Radio //', url: '/shows/melted-radio' },
                          { title: '#AmplifyWomen2020', url: '/shows/amplifywomen2020' },
                          { title: "'Buked & Scorned: The Gospel Radio Hour",
                            url: '/shows/buked-scorned-the-gospel-radio-hour' },
                          { title: '(503)House-Party', url: '/shows/503-house-party' },
                          { title: '12 Steps Beyond Prog', url: '/shows/12-steps-beyond' }]

    titles_urls_hashes.each do |titles_urls_hash|
      title = titles_urls_hash[:title]
      url = "#{station.base_url}#{titles_urls_hash[:url]}"
      ActiveRecord::Base.transaction do
        # broadcast = Broadcast.find_or_initialize_by!(station:, url:)
        byebug
        broadcast = Broadcast.where(url:).first_or_initialize
        broadcast.update_broadcast_title(title, url)
      rescue StandardError => e
        scrape_logger("Error updating broadcast: #{e.message}")
      end
    end
  end

  private

  def fetch_all_broadcast_titles(station_broadcast_index_url)
    html_content = URI.open(station_broadcast_index_url)

    doc = Nokogiri::HTML(html_content)

    doc.css('div.title a').map do |a_element|
      { title: a_element.text, url: a_element['href'] }
    end
  end

  def scrape_logger(message)
    puts message
  end
end
