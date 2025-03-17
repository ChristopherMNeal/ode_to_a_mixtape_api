# frozen_string_literal: true

require 'i18n'

class Artist < ApplicationRecord
  include Normalizable

  normalize_column :name, :normalized_name
  has_many :albums, dependent: :nullify
  has_many :songs, dependent: :nullify

  validates :name, presence: true
  validates :normalized_name, uniqueness: true
end
