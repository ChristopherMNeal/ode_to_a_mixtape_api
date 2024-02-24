# frozen_string_literal: true

class Song < ApplicationRecord
  belongs_to :album, optional: true
  belongs_to :genre
  has_many :playlist_songs
  has_many :playlists, through: :playlist_songs
  has_many :artist_songs
  has_many :artists, through: :artist_songs

  validates :name, presence: true
  validates :name, uniqueness: { scope: :album_id }
end
