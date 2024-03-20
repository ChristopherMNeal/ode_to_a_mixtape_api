# frozen_string_literal: true

require 'open-uri'
require 'nokogiri'
require 'net/http'
# require 'csv'
require 'date'
# require 'fileutils'

class ScrapeBroadcasts
  def call(broadcast, start_date = nil, end_date = nil)
    # if no start date is provided, find the date of the most recent broadcast
    start_date = broadcast.playlists.maximum(:air_date) || Date.new(1990) if start_date.nil?
    scrape_broadcast(broadcast, start_date, end_date)
  end

  private

  def scrape_broadcast(broadcast, start_date, end_date)
    scrape_logger "Scraping broadcast: #{broadcast.title}, start date: #{start_date}, end date: #{end_date || 'none'}"
    page_number = 1
    base_url = broadcast.station.base_url
    broadcast_name_for_url = broadcast.url.split('/').last

    loop do
      broadcasts_index_paginated_url =
        "#{base_url}/programs/#{broadcast_name_for_url}page:#{page_number}?url=broadcasts%2F#{broadcast_name_for_url}"

      paginated_broadcast_index = open_url(broadcasts_index_paginated_url)
      break unless paginated_broadcast_index

      if page_number == 1
        add_broadcast_start_time(broadcast, paginated_broadcast_index)
        update_broadcast_details(broadcast, station, djs)
      end

      scrape_logger "Loaded paginated broadcast page #{page_number}"

      # get each broadcast on the page
      broadcast_divs = paginated_broadcast_index.css('div.broadcasts-container div.broadcast')
      broadcast_divs.each do |broadcast_div|
        broadcast_date = process_broadcast_date(broadcast_div)

        if end_date && broadcast_date >= end_date
          scrape_logger "Skipping broadcast from #{broadcast_date}"
          next
        elsif broadcast_date < start_date
          scrape_logger 'Reached target date, stopping'
          break
        end

        broadcast_show_url = base_url + broadcast_div.css('div.title a').attribute('href').value
        title = broadcast_div.css('div.title a').text.strip

        scrape_logger "Processing: #{broadcast_date.strftime('%I:%M%p, %m-%d-%Y')} - #{title}"

        broadcast_show_page = open_url(broadcast_show_url)
        next unless broadcast_show_page

        tracks_hash = parse_tracks(broadcast_show_page)
        find_or_create_songs(tracks_hash)
        find_or_create_playlist(broadcast_date, title, broadcast_show_url, broadcast_show_page, tracks_hash, broadcast)
      end

      unless next_page_available?(paginated_broadcast_index)
        scrape_logger 'No more pages available, stopping'
        break
      end

      page_number += 1
    end
  end

  def process_broadcast_date(broadcast_div)
    DateTime.strptime(broadcast_div.css('div.date').text, '%I:%M%p, %m-%d-%Y')
  end

  def add_broadcast_start_time(broadcast, paginated_broadcast_index)
    air_times = paginated_broadcast_index.css('div.air_times-container')
    air_day, air_time_start, air_time_end =
      if air_times
        parse_air_times(air_times)
      else
        most_recent_broadcast_air_time(paginated_broadcast_index)
      end

    # sometimes air_time_end is nil
    if (0..6).include?(air_day) && air_time_start
      broadcast.update(air_day:, air_time_start:, air_time_end:)
    else
      scrape_logger "Unable to determine air times for broadcast: #{broadcast.title}"
    end
  end

  def parse_air_times(air_times)
    air_day_string = air_times.css('span.weekday').text
    air_day = Date::DAYNAMES.index(air_day_string.singularize)

    start_time_string = air_times.css('span.start').text
    air_time_start = Time.parse(start_time_string)

    end_time_string = air_times.css('span.end').text
    air_time_end = Time.parse(end_time_string)
    [air_day, air_time_start, air_time_end]
  end

  def most_recent_broadcast_air_time(paginated_broadcast_index)
    most_recent_broadcast = paginated_broadcast_index.css('div.broadcasts-container div.broadcast').first
    most_recent_broadcast_date = process_broadcast_date(most_recent_broadcast)
    [most_recent_broadcast_date.wday, most_recent_broadcast_date, nil]
  end

  # def open_url(url)
  #   Nokogiri::HTML(URI.open(url))
  # rescue OpenURI::HTTPError => e
  #   scrape_logger "Error opening page #{url}: #{e.message}"
  #   nil
  # end

  def open_url(url)
    uri = URI.parse(url)
    response = Net::HTTP.get_response(uri)

    if response.is_a?(Net::HTTPSuccess)
      Nokogiri::HTML(response.body)
    else
      scrape_logger "Error fetching page #{url}: #{response.message}"
      nil
    end
  rescue URI::InvalidURIError => e
    scrape_logger "Invalid URI #{url}: #{e.message}"
    nil
  end

  def process_broadcast_download_urls(broadcast_broadcast_page)
    broadcast_show_page.css('a.player').map { |download_url| download_url['href'] }
  end

  def next_page_available?(paginated_broadcast_index)
    !paginated_broadcast_index.css('div.pagination-container div.pagination-inner span.next a').empty?
  end

  def parse_tracks(broadcast_show_page)
    date = broadcast_show_page.css('div.date').text.split(',').last.strip
    broadcast_show_page.css('div.creek-playlist li.creek-track').map.with_index do |track, index|
      song_time_string = track.css('span.creek-track-time').text
      song_datetime = DateTime.strptime("#{date}, #{song_time_string}", '%m-%d-%Y, %I:%M%p')
      {
        index + 1 =>
          {
            time_string: song_time_string,
            start_time: song_datetime,
            title: track.css('span.creek-track-title').text.strip,
            artist: track.css('span.creek-track-artist').text.strip,
            album: track.css('span.creek-track-album').text.strip,
            label: track.css('span.creek-track-label').text.strip
          }
      }
    end
  end

  def find_or_create_songs(tracks_hash)
    ActiveRecord::Base.transaction do
      tracks_hash.each_value do |track_hash|
        artist = Artist.find_or_create_by!(name: track_hash[:artist])
        album = Album.find_or_create_by!(title: track_hash[:album], artist:)
        record_label = RecordLabel.find_or_create_by!(name: track_hash[:label])

        song = Song.find_or_create_by!(
          title: track_hash[:title],
          album:,
          record_label:
        )

        ArtistsSong.find_or_create_by!(artist:, song:)
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    scrape_logger "Failed to create songs: #{e.message}"
  end

  def find_or_create_playlist(broadcast_date, title, broadcast_show_url, broadcast_show_page, tracks_hash, show)
    download_urls = process_broadcast_download_urls(broadcast_show_page)
    scrape_logger "More than two download URLs found for #{title}" if download_urls.length > 2

    playlist = Playlist.find_or_initialize_by(playlist_url: broadcast_show_url)
    return unless playlist.new_record?

    playlist.update(
      title:,
      air_date: broadcast_date,
      station: broadcast.station,
      original_playlist_id:,
      download_url_1: download_urls[0],
      download_url_2: download_urls[1],
      scraped_data: tracks_hash
    )
  end

  def find_or_create_playlist_songs(playlist, tracks_hash)
    tracks_hash.each do |track_number, track_hash|
      song = Song.find_by(title: track_hash[:title])

      PlaylistsSong.find_or_create_by(
        playlist_id: playlist.id,
        song_id: song.id,
        position: track_number,
        air_date: track_hash[:start_time]
      )
    end
  end

  def update_broadcast_details(broadcast, station, djs)
    broadcast_url = broadcast.url
    broadcast_page = URI.open(broadcast_url)
    doc = Nokogiri::HTML(broadcast_page)
    djs.update(
      bio: doc.css('div.full-description p').map { |node| node.text.strip }.join("\n"),
      dj_names: doc.css('div.hosts-container a').text,
      url: doc.css('div.hosts-container a').first['href']
    )
  end

  def scrape_logger(message)
    Rails.logger.info message
  end
end
