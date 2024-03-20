# frozen_string_literal: true

class Artist < ApplicationRecord
  has_many :artist_songs
  has_many :songs, through: :artist_songs
  has_many :albums_artists
  has_many :albums, through: :albums_artists

  validates :name, presence: true
end
