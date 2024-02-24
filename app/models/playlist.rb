# frozen_string_literal: true

class Playlist < ApplicationRecord
  belongs_to :dj
  belongs_to :station
  belongs_to :original_playlist, class_name: 'Playlist', optional: true
  has_many :playlist_songs
  has_many :songs, through: :playlist_songs

  validates :title, presence: true
  validates :playlist_url, uniqueness: true, allow_blank: true
  validates :playlist_url, format: { with: /\Ahttps?:\/\/.*\z/, message: 'must start with http:// or https://' }, allow_blank: true
end
