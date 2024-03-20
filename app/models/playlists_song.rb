# frozen_string_literal: true

class PlaylistsSong < ApplicationRecord
  belongs_to :playlist
  belongs_to :song
end
