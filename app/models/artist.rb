# frozen_string_literal: true

class Artist < ApplicationRecord
  has_many :albums
  has_many :songs

  validates :name, presence: true
end
