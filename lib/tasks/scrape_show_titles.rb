# frozen_string_literal: true

require 'open-uri'
require 'nokogiri'

class ScrapeShowTitles
  def call(station_show_index_url = 'https://xray.fm/shows/all')
    titles_urls_hash = fetch_all_show_titles(station_show_index_url)
    titles_urls_hash.each do |title, url|
      titleize_url = url.split('/').last.gsub('-', ' ').titleize
      show = Show.find_or_create_by(url:)
      show.update_title(show, titleize_url, title)
    end
  end

  private

  def fetch_all_show_titles(station_show_index_url)
    html_content = URI.open(station_show_index_url)

    doc = Nokogiri::HTML(html_content)

    doc.css('div.title a').map do |a_element|
      { title: a_element.text, url: a_element['href'] }
    end
  end

  def update_show_details(show)
    # show.station.base_url = 'https://xray.fm'
    # full_show_url = "#{show.station.base_url}#{show.url}"
    full_show_url = 'https://xray.fm/shows/strange-babes'
    show_page = URI.open(full_show_url)
    doc = Nokogiri::HTML(show_page)
    show.djs.update(
      bio: doc.css('div.full-description p').map { |node| node.text.strip }.join("\n"),
      dj_names: doc.css('div.hosts-container a').text,
      url: doc.css('div.hosts-container a').first['href']
    )
  end

  def update_title(show, titleize_url, title)
    if show.new_record?
      show.update(title:, old_title: titleize_url)
      update_show_details(show)
    elsif show.title && show.title != title
      show.update(old_title: show.title, title:)
    end
  end
end
