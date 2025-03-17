# frozen_string_literal: true

class Station < ApplicationRecord
  has_many :broadcasts, dependent: :nullify
  has_many :djs_stations, dependent: :destroy
  has_many :djs, through: :djs_stations, dependent: :nullify

  # rubocop:disable Rails/UniqueValidationWithoutIndex
  validates :name, presence: true, uniqueness: true
  validates :base_url, uniqueness: true, presence: true
  validates :broadcasts_index_url, uniqueness: true, presence: true
  # rubocop:enable Rails/UniqueValidationWithoutIndex
end
