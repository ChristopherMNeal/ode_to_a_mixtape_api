# frozen_string_literal: true

class BroadcastSerializer < ActiveModel::Serializer
  attributes :id, :title, :url, :air_day, :air_time_start, :air_time_end, :active
  belongs_to :station
  belongs_to :dj
  has_many :playlists
end
