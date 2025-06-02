# frozen_string_literal: true

require 'open-uri'
require 'nokogiri'
require 'net/http'
require 'date'

# I should make this an instance method of the Broadcast model?
# Usage: ScrapeBroadcasts.new.call(broadcast, start_date, end_date)
# start_date and end_date are inclusive. If you want to scrape a single broadcast, set both to the broadcast date.
# Start date and end date are optional.
# If no start date is provided, the most recent playlist date in the database is used.
# If no playlists are in the database, the start date is set to 1901-12-12, the date of the first radio broadcast.
# If no end date is provided, all broadcasts after the start date are scraped.
class ScrapeBroadcasts # rubocop:disable Metrics/ClassLength
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

  # private

  def scrape_broadcasts # rubocop:disable Metrics
    scrape_logger "Scraping broadcast: #{broadcast.title}, start date: #{start_date}, end date: #{end_date || 'none'}"
    base_url = broadcast.station.base_url
    broadcast_name_for_url = broadcast.url.split('/').last
    update_broadcast_details(base_url, broadcast_name_for_url)

    page_number = find_start_date_page_number(base_url, broadcast_name_for_url)

    loop do # rubocop:disable Metrics/BlockLength
      paginated_broadcast_index = open_broadcasts_index_page(base_url, broadcast_name_for_url, page_number)
      break unless paginated_broadcast_index

      scrape_logger "Loaded paginated broadcast page #{page_number}"

      # get each broadcast on the page
      broadcast_divs = paginated_broadcast_index.css('div.broadcasts-container div.broadcast')

      # reverse the order of the broadcasts so we can start from the oldest playlist
      broadcast_divs.reverse.each do |broadcast_div|
        broadcast_date = parse_broadcast_date(broadcast_div)

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

        broadcast_show_page = open_url(broadcast_show_url)
        next unless broadcast_show_page

        tracks_hash_array = parse_tracks(broadcast_show_page)
        ActiveRecord::Base.transaction(requires_new: true) do
          playlist = find_or_create_playlist(
            broadcast_date, title, broadcast_show_url, broadcast_show_page, tracks_hash_array, broadcast
          )
          playlist.create_records_from_tracks_hash
        end
      end

      break if page_number == 1

      page_number -= 1
    end
    update_air_time_end
    broadcast.update(last_scraped_at: Time.zone.now)
    scrape_logger("Finished scraping broadcast: #{broadcast.title}\n\n")
  end

  def get_start_date(start_date) # rubocop:disable Metrics/MethodLength
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

  def open_broadcasts_index_page(base_url, broadcast_name_for_url, page_number)
    # This should minimize duplicate requests made while searching for the last available page number
    # Will it use too much memory?
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

  def find_start_date_page_number(base_url, broadcast_name_for_url) # rubocop:disable Metrics
    page_number = 1
    previous_page_start_date = Time.zone.today.end_of_day

    loop do
      paginated_broadcast_index = open_broadcasts_index_page(base_url, broadcast_name_for_url, page_number)
      unless paginated_broadcast_index
        scrape_logger "Failed to load paginated broadcast index page for #{broadcast.title} on page #{page_number}"
        break
      end

      broadcast_dates = fetch_broadcast_dates(paginated_broadcast_index)
      break if broadcast_dates.empty?

      min_date = broadcast_dates.min.beginning_of_day
      # max_date = broadcast_dates.max.end_of_day
      max_date = previous_page_start_date

      scrape_logger "Page #{page_number}: #{min_date} - #{max_date}"
      scrape_logger "Start date: #{start_date}"

      if start_date.between?(min_date, max_date)
        # if the start date is within the range of dates on this page, break and return page_number
        break
      elsif start_date < min_date
        # If the start date is before the earliest date on this page and this isn't the last page,
        # skip to the last available page link. If it's the last page, break and return page_number.
        break unless next_page_available?(paginated_broadcast_index)

        # page_number = last_available_page_number(paginated_broadcast_index)
        previous_page_start_date = min_date
        page_number += 1
        # elsif start_date > max_date
        #   # If the start date is after the latest date on this page, go back a page unless it's the first page
        #   break if page_number == 1
        #
        #   page_number -= 1
      else
        scrape_logger "Something went wrong while searching for the start date page number for #{broadcast.title}"
      end
    end
    page_number
  end

  def last_available_page_number(paginated_broadcast_index)
    pagination_container = paginated_broadcast_index.css('div.pagination-container')
    page_numbers = pagination_container.css('span a').map do |link|
      link['href'][/page:(\d+)/, 1].to_i if link['href'].include?('page:')
    end.compact
    # page_numbers = pagination_container.css('span a').map { |link| link.text }
    page_numbers.max
  end

  def fetch_broadcast_dates(paginated_broadcast_index)
    paginated_broadcast_index.css('div.broadcasts-container div.broadcast').map do |broadcast_div|
      parse_broadcast_date(broadcast_div)
    end
  end

  def parse_broadcast_date(broadcast_div)
    DateTime.strptime(broadcast_div.css('div.date').text, '%I:%M%p, %m-%d-%Y')
  end

  # May need to rethink this. Air times change so we can be flexible and update the air times regularly.
  # Broadcast air times should represent the current schedule. Currently, the data is only used for scraping purposes,
  # so no big deal if it's not accurate due to a typo on the website.
  def update_air_time_end # rubocop:disable Metrics
    return unless broadcast.playlists.joins(:playlists_songs).where.not(air_date: nil).exists?

    # get the time of the last song, then round to the top of the hour
    most_recent_broadcast_with_songs =
      broadcast.playlists.joins(:playlists_songs).where.not(air_date: nil).order(air_date: :desc)
    return if most_recent_broadcast_with_songs.blank?

    first_song_start = most_recent_broadcast_with_songs.last.playlists_songs.minimum(:air_date)
    return if first_song_start.nil?

    first_song_time_secs = first_song_start.seconds_since_midnight
    air_time_secs = broadcast.air_time_start.seconds_since_midnight

    # Get absolute difference in seconds, accounting for crossing midnight
    diff_secs = (first_song_time_secs - air_time_secs).abs
    diff_secs = 24.hours - diff_secs if diff_secs > 12.hours

    # Check that the first song starts approximately at the same time as the broadcast, within a generous margin
    if diff_secs > 1.hour
      scrape_logger <<~MESSAGE
        First song start time is too far from broadcast start time for #{broadcast.title}.
        Maybe the time changed? First song start: #{first_song_start}, broadcast start: #{broadcast.air_time_start}
      MESSAGE
      return
    end

    last_song_start = most_recent_broadcast_with_songs.last.playlists_songs.maximum(:air_date)
    broadcast.update(air_time_end: last_song_start.end_of_hour)
  end

  def add_broadcast_start_time(paginated_broadcast_index) # rubocop:disable Metrics
    air_times = paginated_broadcast_index.css('div.airtimes-container')

    air_day, air_time_start, air_time_end =
      if air_times.present? && air_times.css('span.weekday').present?
        parse_air_times(air_times)
      else
        most_recent_broadcast_air_time(paginated_broadcast_index)
      end

    # air_time_end is usually nil. It will be updated using the playlist data after the most recent playlist is found.
    if (0..6).include?(air_day) && air_time_start
      broadcast.assign_attributes(air_day:, air_time_start:, air_time_end:)
      broadcast.save! if broadcast.changed?
    else
      scrape_logger "Unable to determine air times for broadcast: #{broadcast.title}"
    end
  end

  def parse_air_times(air_times) # rubocop:disable Metrics
    # Need to handle multiple dates/times in the air times span, like in https://xray.fm/shows/80lb-cardstock,
    # Broadcast.find(7), which airs on Tuesday and Wednesday. TODO: change the air_day field to an array
    # For now, I'll just take the first day:
    air_day_string = air_times.css('span.weekday').map(&:text).first
    return if air_day_string.blank?

    air_days_array = DayOfWeek.find_day_names_in_string(air_day_string)
    air_days = air_days_array.map { |day_str| DayOfWeek.integer_from_day_of_week(day_str) }
    # It's possible to find multiple days in the string. If so we can log it and take the first one.
    if air_days.length > 1
      scrape_logger "Multiple air days found for broadcast: #{broadcast.title}. Using the first one: #{air_days_array}"
    end
    air_day = air_days.first

    start_time_string = air_times.css('span.start').map(&:text).first
    end_time_string = air_times.css('span.end').map(&:text).first

    air_time_start = parse_time_string(start_time_string)
    air_time_end = parse_time_string(end_time_string)

    [air_day, air_time_start, air_time_end]
  end

  def parse_time_string(time_string)
    return nil if time_string.blank?

    Time.zone.parse(time_string)
  end

  def most_recent_broadcast_air_time(paginated_broadcast_index)
    broadcast_date = fetch_broadcast_dates(paginated_broadcast_index).max
    return unless broadcast_date

    [broadcast_date.wday, broadcast_date, nil]
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
    broadcast_show_page.css('a.player').pluck('href')
  end

  def next_page_available?(paginated_broadcast_index)
    !paginated_broadcast_index.css('div.pagination-container div.pagination-inner span.next a').empty?
  end

  def parse_tracks(broadcast_show_page) # rubocop:disable Metrics
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

  def find_or_create_playlist(broadcast_date, title, broadcast_show_url, broadcast_show_page, tracks_hash, broadcast) # rubocop:disable Metrics
    download_urls = process_broadcast_download_urls(broadcast_show_page)
    scrape_logger "#{download_urls.length} download URLs found for #{title}" if download_urls.length > 2

    playlist = Playlist.find_or_initialize_by(playlist_url: broadcast_show_url)

    playlist.update!(
      title:,
      air_date: broadcast_date,
      station_id: broadcast.station.id,
      broadcast_id: broadcast.id,
      download_url_1: download_urls[0],
      download_url_2: download_urls[1]
    )
    playlist_import = PlaylistImport.find_or_initialize_by(playlist_id: playlist.id)
    playlist_import.update(scraped_data: tracks_hash)
    playlist
  end

  def calculate_frequency_in_days(most_recent_dates)
    if most_recent_dates.count > 2
      most_recent_dates.each_cons(2).map { |a, b| (a - b).to_i }.max
    else
      123 # allows for an annual broadcast to be considered active: when multiplied by 3 is 369 days. It's arbitrary.
    end
  end

  def determine_active_status(most_recent_dates, frequency_in_days)
    # This could be configurable in the future.
    # Currently set to 3 times the frequency of the broadcast or 15 days, whichever is greater,
    # to allow for holidays, vacations, and schedule changes.
    inactivity_threshold = [frequency_in_days * 3, 15].max
    last_playlist_date = most_recent_dates.max
    if last_playlist_date
      (Time.zone.today - inactivity_threshold.days) < last_playlist_date
    else
      # Inactive if no playlists and broadcast data is over a year old.
      # This is a generous threshold for inactivity and could be adjusted if we're seeing too many false positives.
      !(broadcast.created_at < 1.year.ago && broadcast.playlists.empty?)
    end
  end

  def update_broadcast_details(base_url, broadcast_name_for_url) # rubocop:disable Metrics
    paginated_broadcast_index = open_broadcasts_index_page(base_url, broadcast_name_for_url, 1)
    return if paginated_broadcast_index.blank?

    most_recent_dates = fetch_broadcast_dates(paginated_broadcast_index)
    broadcast.frequency_in_days = calculate_frequency_in_days(most_recent_dates)
    broadcast.active = determine_active_status(most_recent_dates, broadcast.frequency_in_days)
    add_broadcast_start_time(paginated_broadcast_index)
    broadcast.save! if broadcast.changed?

    dj = scrape_dj_info(paginated_broadcast_index, broadcast)
    broadcast.update(dj:)
  end

  def scrape_dj_info(doc, broadcast) # rubocop:disable Metrics
    scrape_logger "No DJ info found for broadcast: #{broadcast.title}" if doc.css('div.content-center').empty?

    dj_name = doc.css('div.content-center h1.main-title').text
    dj = Dj.find_or_create_by(dj_name:)

    bio = doc.css('div.full-description p').map { |node| node.text.strip }.join("\n") || ''
    member_names = doc.css('div.hosts-container a').text || ''
    email = scan_for_emails(bio).join(', ') || ''
    instagram, twitter, facebook = scan_for_social_media(bio, 'instagram.com', 'twitter.com', 'facebook.com')

    dj.assign_attributes(
      bio:,
      member_names:,
      email:,
      twitter:,
      instagram:,
      facebook:
    )
    dj.save! if dj.changed?

    scrape_djs_station_info(doc, dj)
    dj
  end

  def scrape_djs_station_info(doc, dj_record)
    station = broadcast.station
    host_container = doc.css('div.hosts-container a').first
    url = host_container.nil? ? '' : host_container['href'] || ''

    DjsStation.find_or_create_by(dj: dj_record, station:, profile_url: url)
  end

  def scan_for_social_media(bio, *social_media_sites)
    social_media_sites.map do |site|
      bio.scan(%r{#{site}/\w+}).map { |a| a.split('/').last }.uniq.join(', ') || ''
    end
  end

  def scan_for_emails(text)
    text.scan(/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/i).uniq
  end

  def scrape_logger(message)
    ScrapeLogger.log(message)
  end
end
