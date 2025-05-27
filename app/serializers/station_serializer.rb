# frozen_string_literal: true

class StationSerializer < ActiveModel::Serializer
  attributes :id, :name, :call_sign, :city, :state, :base_url, :frequencies
  has_many :broadcasts
end
