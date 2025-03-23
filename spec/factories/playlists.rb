# frozen_string_literal: true

FactoryBot.define do
  factory :playlist do
    sequence(:title) { |n| "Ode to a Mixtape#{n}" }
    sequence(:air_date) { |n| Time.zone.today - n.weeks }
    playlist_url { "http://xray.fm/broadcasts/#{SecureRandom.uuid}" }
    station
    broadcast
    download_url_1 { 'https://cdn.xray.fm/audio/strange-babes/StrangeBabesMV042721.mp3' }
    download_url_2 { nil }

    after(:create) { |playlist| create(:playlist_import, playlist:) }
  end
end
