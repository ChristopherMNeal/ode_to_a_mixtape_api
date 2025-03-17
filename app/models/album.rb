# frozen_string_literal: true

class Album < ApplicationRecord
  belongs_to :record_label, optional: true
  belongs_to :artist
  belongs_to :genre, optional: true
  has_many :albums_songs, dependent: :destroy
  has_many :songs, through: :albums_songs, dependent: :nullify

  validates :title, presence: true
end
