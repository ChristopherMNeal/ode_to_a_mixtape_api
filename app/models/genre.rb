# frozen_string_literal: true

class Genre < ApplicationRecord
  has_many :songs, dependent: :destroy

  validates :name, presence: true
end
