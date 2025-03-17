# frozen_string_literal: true

class Playlist < ApplicationRecord # rubocop:disable Metrics/ClassLength
  belongs_to :station
  belongs_to :broadcast
  belongs_to :original_playlist, class_name: 'Playlist', optional: true
  has_many :playlists_songs, dependent: :destroy
  has_many :songs, through: :playlists_songs, dependent: :nullify
  has_one :playlist_import

  delegate :scraped_data, to: :playlist_import, allow_nil: true

  validates :title, presence: true
  # validates :broadcast_id, presence: true
  validates :playlist_url, uniqueness: { case_sensitive: true }, allow_blank: false # rubocop:disable Rails/UniqueValidationWithoutIndex
  validates :playlist_url, format: { with: %r{\Ahttps?://.*\z}, message: 'must start with http:// or https://' } # rubocop:disable Rails/I18nLocaleTexts

  def to_s
    "#{broadcast.title}: #{air_date&.strftime('%Y-%m-%d')}: #{title}"
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

  def print_songs
    playlists_songs.joins(song: :artist).order(:position).map { |ps| "#{ps.song.artist.name} - #{ps.song.title}" }
  end

  def rebroadcasts?
    Playlist.exists?(original_playlist_id: id)
  end

  def with_rebroadcasts
    if rebroadcasts?
      Playlist.where(original_playlist_id: id).or(Playlist.where(id:))
    else
      [self]
    end
  end

  # This can move to a service object if using elsewhere
  def sanitize_filename(filename)
    sanitized = filename.gsub(%r{[:/\\*?"<>|]}, '_')
    sanitized = sanitized.gsub(' ', '_')
    sanitized.squeeze('_')
    sanitized.gsub(/\A_|_\z/, '')
  end

  def download_files(target_dir = Rails.root.join('tmp/downloads')) # rubocop:disable Metrics
    filename = "#{broadcast.title}_#{air_date&.strftime('%Y-%m-%d')}_#{title}"
    filename = sanitize_filename(filename).downcase
    file_path = File.join(target_dir, filename)
    FileUtils.mkdir_p(target_dir)

    download_urls = [download_url_1, download_url_2].compact_blank
    multiple_downloads = download_urls.size > 1
    download_urls.each_with_index do |download_url, i|
      file_extension = download_url.split('.').last.downcase
      if %w[mp3 m4a].exclude?(file_extension)
        puts "Skipping download #{download_url} with unexpected extension: #{file_extension}" # rubocop:disable Rails/Output
        next
      end
      file_number = multiple_downloads ? "_#{i + 1}" : ''
      File.binwrite("#{file_path}#{file_number}.#{file_extension}", URI.open(download_url).read) # rubocop:disable Security/Open
      puts "Downloaded to: #{file_path}#{file_number}.#{file_extension}" # rubocop:disable Rails/Output
    end
  rescue StandardError => e
    puts "An error occurred: #{e.message}" # rubocop:disable Rails/Output
  end

  def create_records_from_tracks_hash # rubocop:disable Metrics
    if scraped_data.blank?
      ScrapeLogger.log '    No scraped data to process'
      return
    end

    scraped_data.each do |track_hash| # rubocop:disable Metrics/BlockLength
      artist_name = track_hash['artist']
      label_name = track_hash['label']
      song_title = track_hash['title']
      album_title = track_hash['album']
      if artist_name.blank? || song_title.blank?
        ScrapeLogger.log <<~MESSAGE
          Skipping record with missing artist or song title. Line:
            #{track_hash['time_string']}, #{song_title} by #{artist_name} on #{album_title} (#{label_name})
        MESSAGE
        next
      end

      normalized_name = Normalizable.normalize_text(artist_name)

      ActiveRecord::Base.transaction do
        record_label = label_name.present? ? RecordLabel.find_or_create_by!(name: label_name) : nil
        artist = Artist.find_or_create_by(normalized_name:)
        if artist.new_record?
          artist.update!(name: artist_name)
        else
          preferred_name = NameFormatter.format_name([artist_name, artist.name])
          artist.update!(name: preferred_name) if artist.name != preferred_name
        end

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
        puts "Failed to create record #{e&.record}: #{e.message}" # rubocop:disable Rails/Output
        puts "Line: #{track_hash['time_string']} #{song_title} by #{artist} on #{album} (#{record_label})" # rubocop:disable Rails/Output
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
