# frozen_string_literal: true

class Dj < ApplicationRecord
  has_many :playlists

  validates :name, presence: true
end
