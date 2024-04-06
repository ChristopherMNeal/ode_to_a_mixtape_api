# frozen_string_literal: true

class Playlist < ApplicationRecord
  belongs_to :station
  belongs_to :broadcast
  belongs_to :original_playlist, class_name: 'Playlist', optional: true
  has_many :playlists_songs, dependent: :destroy
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

  # exclude from playlists API endpoint
  def rebroadcast?
    original_playlist.present?
  end

  # exclude from playlists API endpoint
  def songs?
    songs.any?
  end

  def rebroadcasts?
    Playlist.where(original_playlist_id: id).exists?
  end

  def with_rebroadcasts
    if rebroadcasts?
      Playlist.where(original_playlist_id: id).or(Playlist.where(id:))
    else
      [self]
    end
  end

  def create_records_from_tracks_hash
    if scraped_data.blank?
      puts 'No scraped data to process'
      return
    end

    scraped_data.each do |track_hash|
      ActiveRecord::Base.transaction do
        artist_name = track_hash['artist']
        label_name = track_hash['label']
        song_title = track_hash['title']
        album_title = track_hash['album']

        record_label = label_name.present? ? RecordLabel.find_or_create_by!(name: label_name) : nil

        if artist_name.blank? || song_title.blank?
          puts 'Skipping record with missing artist or song title. Line:'
          puts "     #{track_hash['time_string']}, #{song_title} by #{artist_name} on #{album_title} (#{label_name})"
          next
        end

        artist = Artist.find_or_create_by!(name: artist_name)
        song = Song.find_or_create_by!(title: song_title, artist:)
        find_or_create_playlists_songs(song, track_hash)

        next if album_title.blank?

        album = Album.find_or_create_by!(
          title: album_title,
          artist:,
          record_label:
        )
        AlbumsSong.find_or_create_by!(album:, song:)
      rescue ActiveRecord::RecordInvalid => e
        puts "Failed to create record #{e&.record}: #{e.message}"
        puts "Line: #{track_hash['time_string']} #{song_title} by #{artist} on #{album} (#{record_label})"
        raise e
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
