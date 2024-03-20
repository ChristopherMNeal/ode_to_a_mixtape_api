# frozen_string_literal: true

class AlbumsArtist < ApplicationRecord
  belongs_to :album
  belongs_to :artist
end
