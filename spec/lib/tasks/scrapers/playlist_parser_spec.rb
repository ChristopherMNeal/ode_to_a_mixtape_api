# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('lib/tasks/scrapers/broadcast_page_scraper.rb')
require Rails.root.join('lib/tasks/scrapers/playlist_parser.rb')

RSpec.describe PlaylistParser do
  subject(:parser) { described_class.new(broadcast) }

  let(:station) do
    create(
      :station,
      name: 'XRAY.fm',
      base_url:,
      broadcasts_index_url: "#{base_url}/shows/all"
    )
  end
  let(:broadcast) do
    create(
      :broadcast,
      station:,
      title: 'Strange Babes',
      old_title: 'Strange Babes',
      url: "#{base_url}/shows/#{broadcast_name}"
    )
  end
  let(:base_url) { 'https://xray.fm' }
  let(:broadcast_name) { 'strange-babes' }
  let(:broadcast_show_url) { "#{base_url}/broadcasts/#{broadcast_name}/2021-04-27" }
  let(:broadcast_date) { Date.new(2021, 4, 27) }
  let(:title) { 'Strange Babes - April 27, 2021' }
  let(:html_content) { Rails.root.join('spec/fixtures/xray/strange-babes-playlist-01.html').read }
  let(:broadcast_show_page) { Nokogiri::HTML(html_content) }
  let(:download_urls) { ['https://www.mixcloud.com/example/url1/', 'https://soundcloud.com/example/url2'] }

  # The serialized format of the tracks data when stored by Rails
  let(:tracks_hash) do
    [
      {
        'track_number' => 1,
        'time_string' => '4:00PM',
        'start_time' => DateTime.new(2021, 4, 27, 16, 0).as_json,
        'title' => 'Test Song 1',
        'artist' => 'Test Artist 1',
        'album' => 'Test Album 1',
        'label' => 'Test Label 1'
      },
      {
        'track_number' => 2,
        'time_string' => '4:15PM',
        'start_time' => DateTime.new(2021, 4, 27, 16, 15).as_json,
        'title' => 'Test Song 2',
        'artist' => 'Test Artist 2',
        'album' => 'Test Album 2',
        'label' => 'Test Label 2'
      }
    ]
  end

  before do
    # Stub logger to prevent test noise
    allow_any_instance_of(described_class).to receive(:scrape_logger)
  end

  describe '#find_or_create_playlist' do
    before do
      # Stub BroadcastPageScraper to return the download URLs
      allow_any_instance_of(BroadcastPageScraper).to receive(:process_broadcast_download_urls)
        .and_return(download_urls)
    end

    context 'when playlist does not exist' do
      it 'creates a new playlist with the provided data' do
        expect do
          parser.find_or_create_playlist(broadcast_date, title, broadcast_show_url, broadcast_show_page, tracks_hash)
        end.to change(Playlist, :count).by(1)

        playlist = Playlist.find_by(playlist_url: broadcast_show_url)
        expect(playlist).to have_attributes(
          title:,
          air_date: broadcast_date,
          station_id: station.id,
          broadcast_id: broadcast.id,
          download_url_1: download_urls[0],
          download_url_2: download_urls[1]
        )
      end

      it 'creates a playlist import record with the track data' do
        expect do
          parser.find_or_create_playlist(broadcast_date, title, broadcast_show_url, broadcast_show_page, tracks_hash)
        end.to change(PlaylistImport, :count).by(1)

        playlist = Playlist.find_by(playlist_url: broadcast_show_url)
        import = PlaylistImport.find_by(playlist_id: playlist.id)
        expect(import.scraped_data).to eq(tracks_hash)
      end
    end

    context 'when playlist already exists' do
      let!(:existing_playlist) do
        create(
          :playlist,
          title: 'Old Title',
          air_date: broadcast_date - 1.day, # Incorrect date
          station_id: station.id,
          broadcast_id: broadcast.id,
          playlist_url: broadcast_show_url,
          download_url_1: 'old_url_1',
          download_url_2: nil
        )
      end
      let!(:existing_import) do
        create(
          :playlist_import,
          playlist_id: existing_playlist.id,
          scraped_data: [{ 'track_number' => 1, 'title' => 'Old Track' }]
        )
      end

      it 'updates the existing playlist with the new data' do
        expect do
          parser.find_or_create_playlist(broadcast_date, title, broadcast_show_url, broadcast_show_page, tracks_hash)
        end.not_to change(Playlist, :count)

        existing_playlist.reload
        expect(existing_playlist).to have_attributes(
          title:,
          air_date: broadcast_date,
          station_id: station.id,
          broadcast_id: broadcast.id,
          download_url_1: download_urls[0],
          download_url_2: download_urls[1]
        )
      end

      it 'updates the existing playlist import with the new track data' do
        # Spy on the update method to verify it's being called with the right data
        expect_any_instance_of(PlaylistImport).to receive(:update).with(scraped_data: tracks_hash)

        # Call the method and verify no new PlaylistImport is created
        expect do
          parser.find_or_create_playlist(broadcast_date, title, broadcast_show_url, broadcast_show_page, tracks_hash)
        end.not_to change(PlaylistImport, :count)
      end
    end

    context 'when multiple download URLs are found' do
      let(:many_download_urls) { %w[url1 url2 url3 url4] }

      before do
        allow_any_instance_of(BroadcastPageScraper).to receive(:process_broadcast_download_urls)
          .and_return(many_download_urls)
      end

      it 'logs when more than two download URLs are found' do
        expect(parser).to receive(:scrape_logger).with(/4 download URLs found/)
        parser.find_or_create_playlist(broadcast_date, title, broadcast_show_url, broadcast_show_page, tracks_hash)
      end

      it 'only stores the first two download URLs' do
        playlist = parser.find_or_create_playlist(broadcast_date, title, broadcast_show_url, broadcast_show_page,
                                                  tracks_hash)
        expect(playlist.download_url_1).to eq(many_download_urls[0])
        expect(playlist.download_url_2).to eq(many_download_urls[1])
      end
    end
  end
end
