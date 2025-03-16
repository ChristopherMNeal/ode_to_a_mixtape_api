# frozen_string_literal: true

# I had a bug when populating the air time, so this fills in the gaps
class PopulatePlaylistAirTimeFromPlaylistScrapedData
  def perform # rubocop:disable Metrics
    grouped_playlists_songs = PlaylistsSong.joins(:playlist).where(air_date: nil).group_by(&:playlist_id)
    grouped_playlists_songs.each do |playlist_id, playlists_songs|
      playlist = Playlist.find(playlist_id)
      scraped_data = playlist.scraped_data
      air_date = playlist.air_date

      playlists_songs.each do |playlist_song|
        song_data = scraped_data.select { |sd_hash| sd_hash['track_number'] == playlist_song.position }.first
        song_time_string = song_data['time_string'].upcase
        date_time_string = "#{air_date.strftime('%Y-%m-%d')}, #{song_time_string}"
        expected_format = /\A\d{4}-\d{2}-\d{2}, \d{1,2}:\d{2}(AM|PM)\z/

        unless date_time_string.match?(expected_format)
          raise ArgumentError, "Date string '#{date_time_string}' does not match the expected format."
        end

        ActiveRecord::Base.transaction do
          start_time = DateTime.strptime(date_time_string, '%Y-%m-%d, %I:%M%p')
          song_data['start_time'] = start_time
          playlist.save!
          playlist_song.update!(air_date: start_time)
        end
      end
    end
  end
end
