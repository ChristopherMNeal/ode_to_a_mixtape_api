# frozen_string_literal: true

class RecordLabel < ApplicationRecord
  has_many :albums, dependent: :destroy
end
