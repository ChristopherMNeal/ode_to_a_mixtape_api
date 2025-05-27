# frozen_string_literal: true

FactoryBot.define do
  factory :song do
    artist
    sequence(:title) { |n| "Song 2.#{n}" }
    duration { 1 }
    albums { FactoryBot.create_list(:album, 1) }
    genre { nil }
  end
end
