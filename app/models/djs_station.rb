# frozen_string_literal: true

class DjsStation < ApplicationRecord
  belongs_to :dj
  belongs_to :station
end
