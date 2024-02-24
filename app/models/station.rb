# frozen_string_literal: true

class Station < ApplicationRecord
  has_many :playlists

  validates :name, presence: true
  validates :name, uniqueness: true
end
