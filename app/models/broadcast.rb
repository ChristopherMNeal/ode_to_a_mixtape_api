# frozen_string_literal: true

class Broadcast < ApplicationRecord
  belongs_to :station
  belongs_to :dj, optional: true
  has_many :playlists

  validates :title, presence: true
  validates :url, uniqueness: true, presence: true,
                  format: { with: %r{\Ahttps?://.*\z}, message: 'must start with http:// or https://' }
  validates :air_day, inclusion: { in: 0..6, message: '%<value>s is not a valid day' }, allow_nil: true

  def update_broadcast_title(title, url)
    if new_record?
      # some broadcasts have a url that is not the same as the title
      # because of formatting, special characters, or because the title has changed
      titleize_url = url.split('/').last.gsub('-', ' ').titleize.strip
      update(title:, old_title: titleize_url)
    elsif self.title && self.title != title
      update(old_title: self.title, title:)
    end
  end

  # This will be the id of the playlist on the station's website
  def foreign_id
    url.split('/').last
  end

  def first_playlist
    playlists.order(air_date: :asc).first
  end

  def last_playlist
    playlists.order(air_date: :asc).last
  end

  def self.by_station(station)
    where(station:)
  end

  def self.active
    where(active: true)
  end
end
