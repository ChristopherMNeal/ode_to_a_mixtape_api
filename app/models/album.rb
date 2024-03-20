# frozen_string_literal: true

class Album < ApplicationRecord
  belongs_to :record_label, optional: true
  has_many :albums_songs
  has_many :songs, through: :albums_songs
  has_many :albums_artists
  has_many :artists, through: :albums_artists

  validates :title, presence: true
end
