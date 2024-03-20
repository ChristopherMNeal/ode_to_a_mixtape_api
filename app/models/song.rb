# frozen_string_literal: true

class Song < ApplicationRecord
  belongs_to :album, optional: true
  belongs_to :genre, optional: true
  belongs_to :artist
  has_many :playlists_songs
  has_many :playlists, through: :playlists_songs
  has_many :albums_songs
  has_many :albums, through: :albums_songs

  validates :title, presence: true
  validates :title, uniqueness: { scope: :artist_id }
end
