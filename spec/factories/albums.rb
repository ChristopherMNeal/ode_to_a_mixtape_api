# frozen_string_literal: true

FactoryBot.define do
  factory :album do
    title { 'Here Come the Warm Jets' }
    release_date { '2024-01-28' }
    artist { FactoryBot.create(:artist) }
    genre { FactoryBot.create(:genre) }
    record_label { FactoryBot.create(:record_label) }
  end
end
