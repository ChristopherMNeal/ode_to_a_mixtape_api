# frozen_string_literal: true

FactoryBot.define do
  factory :station do
    sequence(:name) { |n| "XRAY.fm#{n}" }
    sequence(:base_url) { |n| "https://xray.fm#{n}" }
    sequence(:broadcasts_index_url) { |n| "https://xray.fm/shows/all#{n}" }
  end
end
