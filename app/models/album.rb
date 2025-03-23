# frozen_string_literal: true

class Album < ApplicationRecord
  include Normalizable

  belongs_to :record_label, optional: true
  belongs_to :artist
  belongs_to :genre, optional: true
  has_many :albums_songs, dependent: :destroy
  has_many :songs, through: :albums_songs, dependent: :nullify

  normalize_column :title, :normalized_title

  validates :title, presence: true
  validates :normalized_title, presence: true, uniqueness: { scope: :artist_id } # rubocop:disable Rails/UniqueValidationWithoutIndex
end
