# frozen_string_literal: true

class Dj < ApplicationRecord
  has_many :djs_stations, dependent: :destroy
  has_many :stations, through: :djs_stations, dependent: :nullify
end
