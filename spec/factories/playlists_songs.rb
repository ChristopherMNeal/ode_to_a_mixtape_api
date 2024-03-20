# frozen_string_literal: true

FactoryBot.define do
  factory :playlists_song do
    playlist { nil }
    song { nil }
    position { 1 }
  end
end
