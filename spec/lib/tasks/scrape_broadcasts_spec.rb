# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('lib/tasks/scrape_broadcasts.rb')

RSpec.describe ScrapeBroadcasts do
  describe '#call' do
    let(:station) do
      FactoryBot.create(
        :station,
        name: 'XRAY.fm',
        base_url: 'https://xray.fm',
        broadcasts_index_url: 'https://xray.fm/shows/all'
      )
    end
    let(:broadcast) do
      FactoryBot.create(
        :broadcast,
        station:,
        title: 'Strange Babes',
        old_title: 'Strange Babes',
        url: 'https://xray.fm/shows/strange-babes'
      )
    end

    let(:html_content_1) { File.read(Rails.root.join('spec/fixtures/xray/strange-babes-broadcast-index-1.html')) }
    let(:html_content_2) { File.read(Rails.root.join('spec/fixtures/xray/strange-babes-broadcast-index-2.html')) }
    let(:playlist_1) { File.read(Rails.root.join('spec/fixtures/xray/strange-babes-playlist-1.html')) }
    let(:playlist_1_air_date) { DateTime.new(2021, 4, 27, 16) }
    let(:playlist_2) { File.read(Rails.root.join('spec/fixtures/xray/strange-babes-playlist-2.html')) }
    let(:playlist_2_air_date) { DateTime.new(2021, 4, 20, 16) }
    let(:playlist_3) { File.read(Rails.root.join('spec/fixtures/xray/strange-babes-playlist-3.html')) }
    let(:playlist_3_air_date) { DateTime.new(2021, 4, 13, 16) }

    before do
      stub_request(:get, 'https://xray.fm/shows/strange-babes').to_return(status: 200, body: html_content_1)
      stub_request(:get, 'https://xray.fm/programs/strange-babes/page:1?url=broadcasts/strange-babes')
        .to_return(status: 200, body: html_content_1)
      stub_request(:get, 'https://xray.fm/programs/strange-babes/page:2?url=broadcasts/strange-babes')
        .to_return(status: 200, body: html_content_2)
      stub_request(:get, 'https://xray.fm/broadcasts/39512').to_return(status: 200, body: playlist_1)
      stub_request(:get, 'https://xray.fm/broadcasts/39409').to_return(status: 200, body: playlist_1)
      stub_request(:get, 'https://xray.fm/broadcasts/39257').to_return(status: 200, body: playlist_1)
    end

    context 'when scraping the most recent 2 playlists' do
      before do
        described_class.new.call(broadcast, playlist_3_air_date + 1.day)
      end

      it 'updates broadcasts more information from the broadcast show page' do
        expect(broadcast).to have_attributes(
          title: 'Strange Babes',
          old_title: 'Strange Babes',
          url: 'https://xray.fm/shows/strange-babes',
          station:,
          air_day: 2,
          air_time_start: '16:00:00',
          # no expected end time because the end time is not provided on the page
          air_time_end: nil
        )
      end

      it 'creates 2 playlists' do
        aggregate_failures do
        expect(broadcast.playlists.count).to eq(2)
        expect(broadcast.playlists.first).to have_attributes(
          title: 'Ballad of A Mix Tape',
          playlist_url: 'https://xray.fm/broadcasts/39512',
          original_playlist_id: nil,
          download_url_1: 'https://cdn.xray.fm/audio/strange-babes/StrangeBabesMV042721.mp3',
          download_url_2: nil
        )
        expect(broadcast.playlists.first.air_date).to eq(playlist_1_air_date.to_s)
        expect(broadcast.playlists.second).to have_attributes(
          title: 'Queens of Noise',
          playlist_url: 'https://xray.fm/broadcasts/39409',
          original_playlist_id: nil,
          download_url_1: 'https://cdn.xray.fm/audio/strange-babes/StrangeBabesMV042721.mp3',
          download_url_2: nil
        )
        expect(broadcast.playlists.second.air_date).to eq(playlist_2_air_date.to_s)
        # expect(broadcast.playlists.map(&:PlaylistsSong)).to eq()
        end
      end
    end
  end
end
