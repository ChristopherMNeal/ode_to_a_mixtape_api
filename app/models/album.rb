# frozen_string_literal: true

class Album < ApplicationRecord
  belongs_to :record_label, optional: true
  belongs_to :artist
  has_many :albums_songs
  has_many :songs, through: :albums_songs

  validates :title, presence: true
end
