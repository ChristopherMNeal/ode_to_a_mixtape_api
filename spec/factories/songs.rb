# frozen_string_literal: true

FactoryBot.define do
  factory :song do
    title { 'MyString' }
    duration { 1 }
    album_id { 1 }
    genre_id { 1 }
  end
end
