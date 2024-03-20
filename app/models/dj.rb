# frozen_string_literal: true

class Dj < ApplicationRecord
  has_many :djs_stations
  has_many :stations, through: :djs_stations
end
