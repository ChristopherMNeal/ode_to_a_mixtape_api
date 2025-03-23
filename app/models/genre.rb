# frozen_string_literal: true

class Genre < ApplicationRecord
  include Normalizable

  has_many :songs, dependent: :nullify
  has_many :albums, dependent: :nullify

  normalize_column :name, :normalized_name

  validates :name, presence: true
  validates :normalized_name, uniqueness: true
end
