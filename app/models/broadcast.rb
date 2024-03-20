# frozen_string_literal: true

class Broadcast < ApplicationRecord
  belongs_to :station
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
      update!(title:, old_title: titleize_url)
    elsif self.title && self.title != title
      update(old_title: self.title, title:)
    end
  end

  def day_of_week_from_integer(integer)
    Date::DAYNAMES[integer]
  end

  def integer_from_day_of_week(day_name)
    Date::DAYNAMES.index(day_name.capitalize)
  end

  # This will be the id of the playlist on the station's website
  def foreign_id
    url.split('/').last
  end
end
