# frozen_string_literal: true

class Show < ApplicationRecord
  belongs_to :station
  has_many :playlists

  validates :title, presence: true
  validates :url, uniqueness: true, presence: true,
                  format: { with: %r{\Ahttps?://.*\z}, message: 'must start with http:// or https://' }

  def update_show_title(title, url)
    if new_record?
      # some shows have a url that is not the same as the title
      # because of formatting, special characters, or because the title has changed
      titleize_url = url.split('/').last.gsub('-', ' ').titleize
      update!(title:, old_title: titleize_url)
    elsif self.title && self.title != title
      update(old_title: self.title, title:)
    end
  end
end
