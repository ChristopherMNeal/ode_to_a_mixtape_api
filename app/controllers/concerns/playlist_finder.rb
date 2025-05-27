# frozen_string_literal: true

# Concern for helping find playlists by various criteria
module PlaylistFinder
  extend ActiveSupport::Concern

  def find_playlists_by_artist(artist_id)
    Playlist.joins(songs: :artist)
            .where(songs: { artist_id: })
            .distinct
            .order(air_date: :desc)
            .limit(20)
  end

  def find_playlists_by_song(song_id)
    Playlist.joins(:playlists_songs)
            .where(playlists_songs: { song_id: })
            .distinct
            .order(air_date: :desc)
            .limit(20)
  end

  def find_playlists_for_date(month, day)
    Playlist.includes(:broadcast, :station)
            .where('EXTRACT(MONTH FROM air_date) = ? AND EXTRACT(DAY FROM air_date) = ?', month, day)
            .order(air_date: :desc)
  end
end
