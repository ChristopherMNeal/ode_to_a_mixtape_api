# frozen_string_literal: true

class Song < ApplicationRecord
  include Normalizable

  belongs_to :genre, optional: true
  belongs_to :artist
  has_many :playlists_songs, dependent: :destroy
  has_many :playlists, through: :playlists_songs, dependent: :nullify
  has_many :albums_songs, dependent: :destroy
  has_many :albums, through: :albums_songs, dependent: :nullify

  normalize_column :title, :normalized_title

  validates :title, presence: true, uniqueness: { scope: :artist_id } # rubocop:disable Rails/UniqueValidationWithoutIndex
  validates :normalized_title, presence: true, uniqueness: { scope: :artist_id } # rubocop:disable Rails/UniqueValidationWithoutIndex

  def to_s
    if artist && albums.any?
      "#{artist.name} - #{title} (#{albums.pluck(:title).join(', ')})"
    else
      "#{artist.name} - #{title}"
    end
  end

  def list_playlists
    playlists.where(original_playlist: nil).map(&:to_s)
  end
end
