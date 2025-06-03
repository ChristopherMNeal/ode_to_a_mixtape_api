# frozen_string_literal: true

# Handles parsing and creation of playlist data
class PlaylistParser
  attr_reader :broadcast

  def initialize(broadcast)
    @broadcast = broadcast
  end

  def find_or_create_playlist(broadcast_date, title, broadcast_show_url, broadcast_show_page, tracks_hash)
    download_urls = BroadcastPageScraper.new(broadcast).process_broadcast_download_urls(broadcast_show_page)
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

  private

  def scrape_logger(message)
    ScrapeLogger.log(message)
  end
end
