# frozen_string_literal: true

class Station < ApplicationRecord
  include Normalizable

  has_many :broadcasts, dependent: :nullify
  has_many :djs_stations, dependent: :destroy
  has_many :djs, through: :djs_stations, dependent: :nullify

  validates :name, presence: true, uniqueness: true
  validates :base_url, uniqueness: true, presence: true
  validates :broadcasts_index_url, uniqueness: true, presence: true
end
