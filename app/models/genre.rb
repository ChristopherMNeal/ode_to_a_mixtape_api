# frozen_string_literal: true

class Genre < ApplicationRecord
  has_many :songs

  validates :name, presence: true
end
