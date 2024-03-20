# frozen_string_literal: true

FactoryBot.define do
  factory :station do
    name { 'XRAY.fm' }
    base_url { 'https://xray.fm' }
    broadcasts_index_url { 'https://xray.fm/shows/all' }
  end
end
