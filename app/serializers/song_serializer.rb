# frozen_string_literal: true

class SongSerializer < ActiveModel::Serializer
  attributes :id, :title, :duration
  belongs_to :artist
  has_many :albums
  has_many :playlists
end
