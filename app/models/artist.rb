# frozen_string_literal: true

require 'i18n'

class Artist < ApplicationRecord
  include Normalizable

  normalize_column :name, :normalized_name
  has_many :albums
  has_many :songs

  validates :name, presence: true
  validates :normalized_name, uniqueness: true
end
