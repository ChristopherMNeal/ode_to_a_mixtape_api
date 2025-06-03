# frozen_string_literal: true

# Responsible for extracting metadata about broadcasts
class BroadcastMetadataExtractor
  attr_reader :broadcast

  def initialize(broadcast)
    @broadcast = broadcast
  end

  def update_broadcast_details(paginated_broadcast_index)
    return if paginated_broadcast_index.blank?

    most_recent_dates = BroadcastIndexScraper.new(broadcast).fetch_broadcast_dates(paginated_broadcast_index)
    broadcast.frequency_in_days = calculate_frequency_in_days(most_recent_dates)
    broadcast.active = determine_active_status(most_recent_dates, broadcast.frequency_in_days)
    add_broadcast_start_time(paginated_broadcast_index)
    broadcast.save! if broadcast.changed?

    dj = scrape_dj_info(paginated_broadcast_index)
    broadcast.update(dj:) if dj
  end

  def add_broadcast_start_time(paginated_broadcast_index)
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

  def update_air_time_end
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

  private

  def parse_air_times(air_times)
    # Need to handle multiple dates/times in the air times span
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
    broadcast_dates = BroadcastIndexScraper.new(broadcast).fetch_broadcast_dates(paginated_broadcast_index)
    broadcast_date = broadcast_dates.max
    return unless broadcast_date

    [broadcast_date.wday, broadcast_date, nil]
  end

  def scrape_dj_info(doc)
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
