# frozen_string_literal: true

class Genre < ApplicationRecord
  has_many :songs, dependent: :nullify
  has_many :albums, dependent: :nullify

  validates :name, presence: true
end
