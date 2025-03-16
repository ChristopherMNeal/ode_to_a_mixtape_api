# frozen_string_literal: true

FactoryBot.define do
  factory :playlist_import do
    scraped_data { [] }
    # Example of a scraped_data hash:
    # scraped_data {
    #   [
    #     { 'album' => 'Repeat',
    #       'label' => 'End of Time',
    #       'title' => 'Stop Having Fun',
    #       'artist' => 'The Wimps',
    #       'start_time' => '2021-04-27T15:54:00.000+00:00',
    #       'time_string' => '3:54pm',
    #       'track_number' => 1 },
    #     { 'album' => '45',
    #       'label' => 'Double Shot',
    #       'title' => 'The Oogum Boogum Song',
    #       'artist' => 'BRENTON WOOD',
    #       'start_time' => '2021-04-27T16:07:00.000+00:00',
    #       'time_string' => '4:07pm',
    #       'track_number' => 2 },
    #     { 'album' => 'Best Of',
    #       'label' => 'RCA',
    #       'title' => 'Good Times',
    #       'artist' => 'Sam Cooke',
    #       'start_time' => '2021-04-27T16:09:00.000+00:00',
    #       'time_string' => '4:09pm',
    #       'track_number' => 3 },
    #     { 'album' => 'Here Is Barbara Lynn',
    #       'label' => 'Light in the Attic',
    #       'title' => 'Maybe We Can Slip Away',
    #       'artist' => 'Barbara Lynn',
    #       'start_time' => '2021-04-27T16:12:00.000+00:00',
    #       'time_string' => '4:12pm',
    #       'track_number' => 4 }
    #   ]
    # }
  end
end
