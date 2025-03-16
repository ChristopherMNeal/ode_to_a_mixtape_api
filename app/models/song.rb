# frozen_string_literal: true

class Song < ApplicationRecord
  belongs_to :album, optional: true
  belongs_to :genre, optional: true
  belongs_to :artist
  has_many :playlists_songs, dependent: :destroy
  has_many :playlists, through: :playlists_songs
  has_many :albums_songs, dependent: :destroy
  has_many :albums, through: :albums_songs

  validates :title, presence: true
  validates :title, uniqueness: { scope: :artist_id } # rubocop:disable Rails/UniqueValidationWithoutIndex

  def to_s
    if album.present?
      "#{artist.name} - #{title} (#{album.title})"
    else
      "#{artist.name} - #{title}"
    end
  end

  def list_playlists
    playlists.where(original_playlist: nil).map(&:to_s)
  end
end
