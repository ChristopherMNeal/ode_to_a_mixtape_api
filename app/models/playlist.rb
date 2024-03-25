# frozen_string_literal: true

class Playlist < ApplicationRecord
  belongs_to :station
  belongs_to :broadcast
  belongs_to :original_playlist, class_name: 'Playlist', optional: true
  has_many :playlists_songs
  has_many :songs, through: :playlists_songs

  validates :title, presence: true
  validates :playlist_url, uniqueness: true, allow_blank: false
  validates :playlist_url, format: { with: %r{\Ahttps?://.*\z}, message: 'must start with http:// or https://' }

  def to_s
    "#{air_date&.strftime('%Y-%m-%d')}: #{title}"
  end

  def external_id
    playlist_url.split('/').last
  end

  def create_records_from_tracks_hash
    if scraped_data.blank?
      puts 'No scraped data to process'
      return
    end

    scraped_data.each do |track_hash|
      ActiveRecord::Base.transaction do
        artist = Artist.find_or_create_by!(name: track_hash['artist'])
        record_label = RecordLabel.find_or_create_by!(name: track_hash['label']) if track_hash['label'].present?
        song_title = track_hash['title']
        album_title = track_hash['album']
        album = Album.find_or_create_by!(
          title: album_title,
          artist:,
          record_label:
        )
        # next if song_title.blank? || artist.blank?

        song = Song.find_or_create_by!(title: song_title, artist:)

        AlbumsSong.find_or_create_by!(album:, song:)
        find_or_create_playlists_songs(song, track_hash)
      rescue ActiveRecord::RecordInvalid => e
        puts "Failed to create song: #{e.message}"
        puts "Line: #{track_hash['time_string']} #{song_title} by #{artist} on #{album} (#{record_label})"
        raise ActiveRecord::Rollback
      end
    end
  end

  def find_or_create_playlists_songs(song, track_hash)
    PlaylistsSong.find_or_create_by!(
      playlist: self,
      song:,
      position: track_hash['track_number'],
      air_date: track_hash['start_time']
    )
  end
end
