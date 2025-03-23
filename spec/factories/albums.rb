# frozen_string_literal: true

FactoryBot.define do
  factory :album do
    sequence(:title) { |n| "Here Come the Warm Jets #{n}" }
    release_date { '2024-01-28' }
    artist
    genre { nil }
    record_label { nil }
  end
end
