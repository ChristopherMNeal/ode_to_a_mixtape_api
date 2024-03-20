# frozen_string_literal: true

require 'open-uri'
require 'nokogiri'
require 'net/http'
require 'date'

# I should make this an instance method of the Broadcast model?
class ScrapeBroadcasts
  def call(broadcast, start_date = nil, end_date = nil)
    # if no start date is provided, find the date of the most recent broadcast in the database to start from
    start_date = if !start_date.nil?
                   start_date
                 elsif broadcast.playlists.present?
                   broadcast.playlists.maximum(:air_date)
                 else
                   Date.new(1901, 12, 12)
                 end
    scrape_broadcasts(broadcast, start_date, end_date)
  end

  private

  def scrape_broadcasts(broadcast, start_date, end_date)
    scrape_logger "Scraping broadcast: #{broadcast.title}, start date: #{start_date}, end date: #{end_date || 'none'}"
    page_number = 1
    base_url = broadcast.station.base_url
    broadcast_name_for_url = broadcast.url.split('/').last

    loop do # rubocop:disable Lint/UnreachableLoop
      broadcasts_index_paginated_url =
        "#{base_url}/programs/#{broadcast_name_for_url}/page:#{page_number}?url=broadcasts%2F#{broadcast_name_for_url}"

      paginated_broadcast_index = open_url(broadcasts_index_paginated_url)
      break unless paginated_broadcast_index

      if page_number == 1
        add_broadcast_start_time(broadcast, paginated_broadcast_index)
        update_broadcast_details(broadcast)
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

        tracks_hash_array = parse_tracks(broadcast_show_page)
        playlist = find_or_create_playlist(broadcast_date, title, broadcast_show_url, broadcast_show_page, tracks_hash_array,
                                           broadcast)
        find_or_create_songs(tracks_hash_array, playlist)
      end

      unless next_page_available?(paginated_broadcast_index)
        scrape_logger 'No more pages available, stopping'
        break
      end

      # page_number += 1
      break # for testing
    end
  end

  def process_broadcast_date(broadcast_div)
    DateTime.strptime(broadcast_div.css('div.date').text, '%I:%M%p, %m-%d-%Y')
  end

  def add_broadcast_start_time(broadcast, paginated_broadcast_index)
    air_times = paginated_broadcast_index.css('div.air_times-container')
    air_day, air_time_start, air_time_end =
      if air_times.present?
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
    air_day = if air_day_string.present?
                Date::DAYNAMES.index(air_day_string.singularize)
              else
                scrape_logger "Unable to determine air times for broadcast: #{broadcast.title}"
                nil
              end

    start_time_string = air_times.css('span.start').text
    end_time_string = air_times.css('span.end').text

    air_time_start = parse_time_string(start_time_string)
    air_time_end = parse_time_string(end_time_string)

    [air_day, air_time_start, air_time_end]
  end

  def parse_time_string(time_string)
    return nil unless time_string.present?

    Time.parse(time_string)
  end

  def most_recent_broadcast_air_time(paginated_broadcast_index)
    most_recent_broadcast = paginated_broadcast_index.css('div.broadcasts-container div.broadcast').first
    most_recent_broadcast_date = process_broadcast_date(most_recent_broadcast)
    [most_recent_broadcast_date.wday, most_recent_broadcast_date, nil]
  end

  def open_url(url)
    # Open the URL, set the stream's encoding to UTF-8, read the content,
    # ensure it's encoded in UTF-8, and parse with Nokogiri
    Nokogiri::HTML(URI.open(url).set_encoding('utf-8').read.encode('UTF-8'))
  rescue OpenURI::HTTPError => e
    # Log any HTTP errors encountered during the fetch
    scrape_logger("Error opening page #{url}: #{e.message}")
    nil
  end

  # another option that appeases RuboCop by using Net::HTTP
  # def open_url(url)
  #   uri = URI.parse(url)
  #   response = Net::HTTP.get_response(uri)
  #
  #   if response.is_a?(Net::HTTPSuccess)
  #     html_content = response.body.force_encoding('UTF-8').encode('UTF-8')
  #     Nokogiri::HTML(html_content)
  #   else
  #     scrape_logger("Error fetching page #{url}: #{response.message}")
  #     nil
  #   end
  # rescue URI::InvalidURIError => e
  #   scrape_logger("Invalid URI #{url}: #{e.message}")
  #   nil
  # end

  def process_broadcast_download_urls(broadcast_show_page)
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

  def find_or_create_songs(tracks_hash_array, playlist)
    ActiveRecord::Base.transaction do
      tracks_hash_array.each do |track_hash|
        artist = Artist.find_or_create_by!(name: track_hash[:artist])
        record_label = RecordLabel.find_or_create_by!(name: track_hash[:label])
        title = track_hash[:title]
        album = Album.find_or_create_by!(title:, artist_id: artist.id, record_label_id: record_label.id)
        song = Song.find_or_create_by!(title:, artist_id: artist.id)

        AlbumsSong.find_or_create_by!(album:, song:)
        AlbumsArtist.find_or_create_by!(album:, artist:)
        find_or_create_playlists_songs(playlist, song, track_hash)
      end
    rescue ActiveRecord::RecordInvalid => e
      scrape_logger "Failed to create songs: #{e.message}"
    end
  end

  def find_or_create_playlist(broadcast_date, title, broadcast_show_url, broadcast_show_page, tracks_hash, broadcast)
    download_urls = process_broadcast_download_urls(broadcast_show_page)
    scrape_logger "More than two download URLs found for #{title}" if download_urls.length > 2

    playlist = Playlist.find_or_initialize_by(playlist_url: broadcast_show_url)

    playlist.update!(
      title:,
      air_date: broadcast_date,
      station_id: broadcast.station.id,
      broadcast_id: broadcast.id,
      download_url_1: download_urls[0],
      download_url_2: download_urls[1],
      scraped_data: tracks_hash
    )
    playlist
  end

  def find_or_create_playlists_songs(playlist, song, track_hash)
    PlaylistsSong.find_or_create_by!(
      playlist_id: playlist.id,
      song_id: song.id,
      position: track_hash[:track_number],
      air_date: track_hash[:start_time]
    )
  end

  def update_broadcast_details(broadcast)
    broadcast_url = broadcast.url
    broadcast_page = URI.open(broadcast_url)
    doc = Nokogiri::HTML(broadcast_page)
    if doc.css('div.content-center').empty?
      scrape_logger "No DJ info found for broadcast: #{broadcast.title}"
      nil
    else
      scrape_dj_info(doc, broadcast)
    end
  end

  def scrape_dj_info(doc, broadcast)
    dj_name = doc.css('div.content-center h1.main-title').text
    dj = Dj.find_or_create_by(dj_name:)

    bio = doc.css('div.full-description p').map { |node| node.text.strip }.join("\n") || ''
    member_names = doc.css('div.hosts-container a').text || ''
    email = bio.scan(/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/i).uniq.join(', ') || ''
    instagram = bio.scan(%r{instagram.com/\w+}).uniq.join(', ') || ''
    twitter = bio.scan(%r{twitter.com/\w+}).map { |a| a.split('/').last }.uniq.join(', ') || ''
    facebook = bio.scan(%r{facebook.com/\w+}).uniq.join(', ') || ''

    dj.update!(
      bio:,
      member_names:,
      email:,
      twitter:,
      instagram:,
      facebook:
    )

    station = broadcast.station
    url = doc.css('div.hosts-container a').first['href']
    return unless url

    djs_station = DjsStation.find_or_create_by(dj:, station:, profile_url: url)
  end

  def scrape_logger(message)
    puts message
  end
end
