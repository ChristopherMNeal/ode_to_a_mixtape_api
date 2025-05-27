# frozen_string_literal: true

class ArtistSerializer < ActiveModel::Serializer
  attributes :id, :name, :bio
  has_many :songs
  has_many :albums
end
