# frozen_string_literal: true

FactoryBot.define do
  factory :playlist do
    sequence(:title) { |n| "Ode to a Mixtape#{n}" } # Corrected this line
    sequence(:air_date) { |n| Time.zone.today - n.weeks }
    broadcast
    station { broadcast.station }
    sequence(:playlist_url) { |n| "https://xray.fm/broadcasts/39512#{n}" }
    download_url_1 { 'https://cdn.xray.fm/audio/strange-babes/StrangeBabesMV042721.mp3' }
    download_url_2 { nil }
    scraped_data { # rubocop:disable Style/BlockDelimiters Metrics
      [
        { 'album' => 'Repeat',
          'label' => 'End of Time',
          'title' => 'Stop Having Fun',
          'artist' => 'The Wimps',
          'start_time' => '2021-04-27T15:54:00.000+00:00',
          'time_string' => '3:54pm',
          'track_number' => 1 },
        { 'album' => '45',
          'label' => 'Double Shot',
          'title' => 'The Oogum Boogum Song',
          'artist' => 'BRENTON WOOD',
          'start_time' => '2021-04-27T16:07:00.000+00:00',
          'time_string' => '4:07pm',
          'track_number' => 2 },
        { 'album' => 'Best Of',
          'label' => 'RCA',
          'title' => 'Good Times',
          'artist' => 'Sam Cooke',
          'start_time' => '2021-04-27T16:09:00.000+00:00',
          'time_string' => '4:09pm',
          'track_number' => 3 },
        { 'album' => 'Here Is Barbara Lynn',
          'label' => 'Light in the Attic',
          'title' => 'Maybe We Can Slip Away',
          'artist' => 'Barbara Lynn',
          'start_time' => '2021-04-27T16:12:00.000+00:00',
          'time_string' => '4:12pm',
          'track_number' => 4 }
      ]
    }
  end
end
