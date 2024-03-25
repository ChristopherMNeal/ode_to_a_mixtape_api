# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Playlist, type: :model do
  describe '#create_records_from_tracks_hash' do
    context 'when scraping a playlist with missing data' do
      let(:scraped_data_with_missing_attributes) do
        [
          { 'album' => 'Love Is The Slug 12',
            'label' => 'Geffen',
            'title' => 'Love Is The Slug',
            'artist' => 'Fuzzbox',
            'start_time' => '2017-01-17T16:55:00.000+00:00',
            'time_string' => '4:55pm',
            'track_number' => 19 },
          { 'album' => '',
            'label' => '',
            'title' => '',
            'artist' => '',
            'start_time' => '2017-01-17T17:03:00.000+00:00',
            'time_string' => '5:03pm',
            'track_number' => 20 },
          { 'album' => 'No Matter How Long the Line...',
            'label' => 'Light In the Attic',
            'title' => 'Which Way To Go',
            'artist' => 'Big Boys',
            'start_time' => '2017-01-17T17:06:00.000+00:00',
            'time_string' => '5:06pm',
            'track_number' => 21 }
        ]
      end
      let(:playlist_with_missing_data) do
        FactoryBot.create(
          :playlist,
          scraped_data: scraped_data_with_missing_attributes
        )
      end

      it 'skips over missing song data without error' do
        expect { playlist_with_missing_data.create_records_from_tracks_hash }.not_to raise_error
      end

      it 'creates songs with complete data' do
        expect { playlist_with_missing_data.create_records_from_tracks_hash }
          .to change { Song.count }
          .from(0)
          .to(2)
        expect(Song.find_by(title: 'Love Is The Slug')).to be_present
        expect(Song.find_by(title: 'Which Way To Go')).to be_present
      end

      it 'does not create a song with missing data' do
        playlist_with_missing_data.create_records_from_tracks_hash
        expect(Song.find_by(title: '').present?).to be false
      end

      it 'creates playlists_songs skipping position 20' do
        playlist_with_missing_data.create_records_from_tracks_hash
        song_titles = scraped_data_with_missing_attributes.map { |a| a['title'] if a['title'].present? }.compact
        expect(playlist_with_missing_data.songs.map(&:title)).to contain_exactly(*song_titles)
        expect(playlist_with_missing_data.playlists_songs.pluck(:position)).to contain_exactly(19, 21)
      end
    end

    context 'when scraping a playlist with duplicate data' do
      let(:scraped_data_with_duplicate_entry) do
        [
          { 'album' => 'Love Is The Slug 12',
            'label' => 'Geffen',
            'title' => 'Love Is The Slug',
            'artist' => 'Fuzzbox',
            'start_time' => '2017-01-17T16:55:00.000+00:00',
            'time_string' => '4:55pm',
            'track_number' => 17 },
          { 'album' => 'All Fall Down',
            'label' => '1972',
            'title' => 'Party of The Mind',
            'artist' => 'The Sound',
            'start_time' => '2017-01-17T17:02:00.000+00:00',
            'time_string' => '5:02pm',
            'track_number' => 18 },
          { 'album' => 'All Fall Down',
            'label' => '1972',
            'title' => 'Party of The Mind',
            'artist' => 'The Sound',
            'start_time' => '2017-01-17T17:03:00.000+00:00',
            'time_string' => '5:03pm',
            'track_number' => 19 }
        ]
      end
      let(:playlist_with_duplicate_entries) do
        FactoryBot.create(
          :playlist,
          scraped_data: scraped_data_with_duplicate_entry
        )
      end

      it 'skips over extra song data without error' do
        expect { playlist_with_duplicate_entries.create_records_from_tracks_hash }.not_to raise_error
      end

      it 'does not create duplicate songs' do
        expect { playlist_with_duplicate_entries.create_records_from_tracks_hash }.to change { Song.count }.by(2)
        expect(Song.where(title: 'Party of The Mind').count).to eq(1)
        expect(Song.where(title: 'Love Is The Slug').count).to eq(1)
      end
    end
  end
end
