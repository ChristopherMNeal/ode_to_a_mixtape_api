# frozen_string_literal: true

FactoryBot.define do
  factory :song do
    sequence(:title) { |n| "Song 2.#{n}" }
    duration { 1 }
    albums { [FactoryBot.create(:album)] }
    genre { FactoryBot.create(:genre) }
  end
end
