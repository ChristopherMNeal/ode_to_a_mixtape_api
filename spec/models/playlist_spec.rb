# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Playlist do
  subject { create(:playlist) }

  describe 'validations' do
    # This test is at odds with rubocop's redundant validation check
    # it { is_expected.to validate_presence_of(:broadcast_id) }
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_uniqueness_of(:playlist_url).case_insensitive }
    it { is_expected.to allow_value('http://example.com').for(:playlist_url) }
    it { is_expected.to allow_value('https://example.com').for(:playlist_url) }
    it { is_expected.not_to allow_value('example.com').for(:playlist_url) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:station) }
    it { is_expected.to belong_to(:broadcast) }
    it { is_expected.to belong_to(:original_playlist).class_name('Playlist').optional }
    it { is_expected.to have_many(:playlists_songs).dependent(:destroy) }
    it { is_expected.to have_many(:songs).through(:playlists_songs) }
  end

  describe '#to_s' do
    let(:playlist) { create(:playlist, air_date: Date.parse('2017-01-17'), title: 'Playlist Title') }

    it 'returns the formatted broadcast title, air date, and playlist title' do
      expect(playlist.to_s).to eq('Strange Babes: 2017-01-17: Playlist Title')
    end
  end

  describe '#external_id' do
    let(:playlist) { create(:playlist, playlist_url: 'http://example.com/playlist-id') }

    it 'returns the id of the playlist on the station website' do
      expect(playlist.external_id).to eq('playlist-id')
    end
  end

  describe '#rebroadcast?' do
    context 'when the playlist is a rebroadcast' do
      let(:original_playlist) { create(:playlist) }
      let(:playlist) { create(:playlist, original_playlist:) }

      it 'returns true' do
        expect(playlist.rebroadcast?).to be true
      end
    end

    context 'when the playlist is not a rebroadcast' do
      let(:playlist) { create(:playlist) }

      it 'returns false' do
        expect(playlist.rebroadcast?).to be false
      end
    end
  end

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
      let(:playlist_with_missing_data) { create(:playlist) }
      let!(:playlist_with_missing_data_import) do
        create(
          :playlist_import,
          playlist: playlist_with_missing_data,
          scraped_data: scraped_data_with_missing_attributes
        )
      end

      it 'skips over missing song data without error' do
        expect { playlist_with_missing_data.create_records_from_tracks_hash }.not_to raise_error
      end

      it 'creates songs with complete data' do
        expect { playlist_with_missing_data.create_records_from_tracks_hash }
          .to change(Song, :count)
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
        song_titles = scraped_data_with_missing_attributes.map { |a| a['title'].presence }.compact
        expect(playlist_with_missing_data.songs.map(&:title)).to match_array(song_titles)
        expect(playlist_with_missing_data.playlists_songs.pluck(:position)).to contain_exactly(19, 21)
      end
    end

    context 'when scraping a playlist without label data' do
      let(:scraped_data_with_missing_label) do
        [
          { 'album' => 'No Matter How Long the Line...',
            'label' => '',
            'title' => 'Which Way To Go',
            'artist' => 'Big Boys',
            'start_time' => '2017-01-17T17:06:00.000+00:00',
            'time_string' => '5:06pm',
            'track_number' => 21 }
        ]
      end
      let(:playlist_with_missing_label) { create(:playlist) }
      let!(:playlist_with_missing_label_import) do
        create(
          :playlist_import,
          playlist: playlist_with_missing_label,
          scraped_data: scraped_data_with_missing_label
        )
      end

      it 'creates song data without error' do
        expect { playlist_with_missing_label.create_records_from_tracks_hash }.not_to raise_error
      end

      it 'creates a song' do
        expect { playlist_with_missing_label.create_records_from_tracks_hash }
          .to change(Song, :count)
          .from(0)
          .to(1)
      end

      it 'creates a song with complete data' do
        playlist_with_missing_label.create_records_from_tracks_hash
        song = Song.find_by(title: 'Which Way To Go')
        expect(song).to be_present
        expect(song.albums).to eq(Album.where(title: 'No Matter How Long the Line...'))
        expect(song.artist).to eq(Artist.find_by(name: 'Big Boys'))
      end

      it 'creates an album without a label' do
        playlist_with_missing_label.create_records_from_tracks_hash
        album = Album.find_by(title: 'No Matter How Long the Line...')
        expect(album).to be_present
        expect(album.record_label).to be_nil
      end

      it 'creates a playlists_song' do
        playlist_with_missing_label.create_records_from_tracks_hash
        song = playlist_with_missing_label.songs.first
        expect(song.title).to eq('Which Way To Go')
        expect(song.playlists_songs.first.position).to eq(21)
      end
    end

    context 'when scraping a playlist without album data' do
      let(:scraped_data_with_missing_album) do
        [
          { 'album' => '',
            'label' => 'Light In the Attic',
            'title' => 'Which Way To Go',
            'artist' => 'Big Boys',
            'start_time' => '2017-01-17T17:06:00.000+00:00',
            'time_string' => '5:06pm',
            'track_number' => 21 }
        ]
      end
      let(:playlist_with_missing_album) { create(:playlist) }
      let!(:playlist_with_missing_album_import) do
        create(
          :playlist_import,
          playlist: playlist_with_missing_album,
          scraped_data: scraped_data_with_missing_album
        )
      end

      it 'skips over missing song data without error' do
        expect { playlist_with_missing_album.create_records_from_tracks_hash }.not_to raise_error
      end

      it 'creates songs with complete data' do
        expect { playlist_with_missing_album.create_records_from_tracks_hash }
          .to change(Song, :count)
          .from(0)
          .to(1)
        expect(Song.find_by(title: 'Which Way To Go')).to be_present
      end

      it 'does not create a song with missing data' do
        playlist_with_missing_album.create_records_from_tracks_hash
        expect(Song.find_by(title: '').present?).to be false
      end

      it 'creates playlists_songs skipping position 20' do
        playlist_with_missing_album.create_records_from_tracks_hash
        song_titles = scraped_data_with_missing_album.map do |a|
          a['title'].presence
        end.compact
        expect(playlist_with_missing_album.songs.map(&:title)).to match_array(song_titles)
        expect(playlist_with_missing_album.playlists_songs.pluck(:position)).to contain_exactly(21)
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
      let(:playlist_with_duplicate_entries) { create(:playlist) }
      let!(:playlist_with_duplicate_entries_import) do
        create(
          :playlist_import,
          playlist: playlist_with_duplicate_entries,
          scraped_data: scraped_data_with_duplicate_entry
        )
      end

      it 'skips over extra song data without error' do
        expect { playlist_with_duplicate_entries.create_records_from_tracks_hash }.not_to raise_error
      end

      it 'does not create duplicate songs' do
        expect { playlist_with_duplicate_entries.create_records_from_tracks_hash }.to change(Song, :count).by(2)
        expect(Song.where(title: 'Party of The Mind').count).to eq(1)
        expect(Song.where(title: 'Love Is The Slug').count).to eq(1)
      end
    end
  end
end
