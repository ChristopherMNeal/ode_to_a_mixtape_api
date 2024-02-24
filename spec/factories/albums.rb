# frozen_string_literal: true

FactoryBot.define do
  factory :album do
    title { 'MyString' }
    release_date { '2024-01-28' }
    artist_id { 1 }
    genre_id { 1 }
    record_label_id { 1 }
  end
end
