# frozen_string_literal: true

class Station < ApplicationRecord
  has_many :broadcasts
  has_many :djs_stations
  has_many :djs, through: :djs_stations

  validates :name, presence: true, uniqueness: true
  validates :base_url, uniqueness: true, presence: true
  validates :broadcasts_index_url, uniqueness: true, presence: true
end
