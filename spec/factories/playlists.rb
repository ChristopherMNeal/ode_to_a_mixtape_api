# frozen_string_literal: true

FactoryBot.define do
  factory :playlist do
    title { 'Ode to a Mixtape' }
    air_date { '2024-01-28 22:42:24' }
    dj_id { 1 }
    station_id { 1 }
    playlist_url { 'https://xray.fm/broadcasts/39512' }
    station_id { 1 }
    original_playlist_id { 1 }
    download_url_1 { 'https://cdn.xray.fm/audio/strange-babes/StrangeBabesMV042721.mp3' }
    download_url_2 { nil }
    scraped_data { '' }
  end
end
