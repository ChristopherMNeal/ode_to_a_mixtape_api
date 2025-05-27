# frozen_string_literal: true

class PlaylistSerializer < ActiveModel::Serializer
  attributes :id, :title, :air_date, :playlist_url, :theme, :holiday, :fund_drive
  belongs_to :broadcast
  belongs_to :station
  has_many :songs
end
