# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'
require Rails.root.join('lib/tasks/scrape_broadcasts.rb')

RSpec.describe ScrapeBroadcasts do
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

  # rubocop:disable RSpec/IndexedLet
  let(:html_content_1) { Rails.root.join('spec/fixtures/xray/strange-babes-broadcast-index-1.html').read }
  let(:html_content_2) { Rails.root.join('spec/fixtures/xray/strange-babes-broadcast-index-2.html').read }
  let(:html_content_3) { Rails.root.join('spec/fixtures/xray/strange-babes-broadcast-index-3.html').read }
  let(:playlist_1) { Rails.root.join('spec/fixtures/xray/strange-babes-playlist-01.html').read }
  let(:playlist_1_air_date) { DateTime.new(2021, 4, 27, 16) }
  let(:playlist_2) { Rails.root.join('spec/fixtures/xray/strange-babes-playlist-02.html').read }
  let(:playlist_2_air_date) { DateTime.new(2021, 4, 20, 16) }
  let(:playlist_3) { Rails.root.join('spec/fixtures/xray/strange-babes-playlist-03.html').read }
  let(:playlist_3_air_date) { DateTime.new(2021, 4, 13, 16) }
  let(:playlist_4_no_songs) { Rails.root.join('spec/fixtures/xray/strange-babes-playlist-04.html').read }
  let(:playlist_4_no_songs_air_date) { DateTime.new(2021, 4, 6, 16) }
  let(:playlist_5) { Rails.root.join('spec/fixtures/xray/strange-babes-playlist-05.html').read }
  let(:playlist_6_bad_data) { Rails.root.join('spec/fixtures/xray/strange-babes-playlist-06.html').read }
  let(:playlist_6_bad_data_air_date) { DateTime.new(2021, 3, 23, 16) }
  let(:playlist_7) { Rails.root.join('spec/fixtures/xray/strange-babes-playlist-07.html').read }
  let(:playlist_8) { Rails.root.join('spec/fixtures/xray/strange-babes-playlist-08.html').read }
  let(:playlist_9) { Rails.root.join('spec/fixtures/xray/strange-babes-playlist-09.html').read }
  let(:playlist_10) { Rails.root.join('spec/fixtures/xray/strange-babes-playlist-10.html').read }
  let(:playlist_11) { Rails.root.join('spec/fixtures/xray/strange-babes-playlist-11.html').read }
  let(:playlist_11_air_date) { DateTime.new(2021, 2, 16, 16) }
  let(:playlist_double_downloads) { Rails.root.join('spec/fixtures/xray/strange-babes-playlist-19.html').read }
  let(:playlist_double_downloads_date) { DateTime.new(2020, 12, 15, 16) }
  # rubocop:enable RSpec/IndexedLet

  before do
    1.upto(3) do |page|
      stub_request(
        :get, "#{base_url}/programs/#{broadcast_name}/page:#{page}?url=broadcasts%2F#{broadcast_name}"
      ).to_return(status: 200, body: send("html_content_#{page}"))
    end

    stub_request(
      :get, "#{base_url}/programs/#{broadcast_name}/page:4?url=broadcasts%2F#{broadcast_name}"
    ).to_return(status: 404, body: '')

    stub_request(
      :get, "#{base_url}/programs/#{broadcast_name}/page:0?url=broadcasts%2F#{broadcast_name}"
    ).to_return(status: 404, body: '')

    stub_request(:get, "#{base_url}/broadcasts/39512").to_return(status: 200, body: playlist_1)
    stub_request(:get, "#{base_url}/broadcasts/39409").to_return(status: 200, body: playlist_2)
    stub_request(:get, "#{base_url}/broadcasts/39257").to_return(status: 200, body: playlist_3)
    stub_request(:get, "#{base_url}/broadcasts/39197").to_return(status: 200, body: playlist_4_no_songs)
    stub_request(:get, "#{base_url}/broadcasts/39091").to_return(status: 200, body: playlist_5)
    stub_request(:get, "#{base_url}/broadcasts/38923").to_return(status: 200, body: playlist_6_bad_data)
    stub_request(:get, "#{base_url}/broadcasts/38873").to_return(status: 200, body: playlist_7)
    stub_request(:get, "#{base_url}/broadcasts/38768").to_return(status: 200, body: playlist_8)
    stub_request(:get, "#{base_url}/broadcasts/38662").to_return(status: 200, body: playlist_9)
    stub_request(:get, "#{base_url}/broadcasts/38540").to_return(status: 200, body: playlist_10)
    stub_request(:get, "#{base_url}/broadcasts/38446").to_return(status: 200, body: playlist_11)
    stub_request(:get, "#{base_url}/broadcasts/37486").to_return(status: 200, body: playlist_double_downloads)
  end

  describe '#call' do
    let(:call_task) { described_class.new(broadcast, start_date, end_date).call }
    let(:start_date) { nil }
    let(:end_date) { nil }

    context 'when scraping the most recent 2 playlists' do
      let(:start_date) { playlist_2_air_date }

      before { call_task }

      it 'updates broadcasts more information from the broadcast show page' do # rubocop:disable RSpec/ExampleLength
        dj = Dj.find_by(dj_name: 'Strange Babes')
        expect(dj).to have_attributes(
          member_names: 'Jen O, KM Fizzy, and Magic Beans',
          email: 'strangebabesbooking@gmail.com',
          twitter: 'strangebabes',
          instagram: 'strangebabes',
          facebook: 'strangebabespdx'
        )
        expect(broadcast).to have_attributes(
          title: 'Strange Babes',
          old_title: 'Strange Babes',
          url: "#{base_url}/shows/#{broadcast_name}",
          station:,
          dj:,
          air_day: 2,
          active: false,
          frequency_in_days: 7
        )
        expect(broadcast.air_time_start.strftime('%H:%M')).to eq('16:00')
        expect(broadcast.air_time_end.strftime('%H:%M')).to eq('17:59')
        expect(broadcast.last_scraped_at).to be_within(1.minute).of(Time.zone.now)
      end

      it 'creates 2 playlists' do # rubocop:disable RSpec/ExampleLength
        aggregate_failures do
          expect(broadcast.playlists.count).to eq(2)
          expect(broadcast.playlists.second).to have_attributes(
            title: 'Ballad of A Mix Tape',
            playlist_url: "#{base_url}/broadcasts/39512",
            original_playlist_id: nil,
            download_url_1: 'https://cdn.xray.fm/audio/strange-babes/StrangeBabesMV042721.mp3',
            download_url_2: nil
          )
          expect(broadcast.playlists.second.air_date).to eq(playlist_1_air_date.to_s)
          expect(broadcast.playlists.first).to have_attributes(
            title: 'Queens of Noise',
            playlist_url: "#{base_url}/broadcasts/39409",
            original_playlist_id: nil,
            download_url_1: 'https://cdn.xray.fm/audio/strange-babes/QueensofNoiseJenOLastshow.mp3',
            download_url_2: nil
          )
          expect(broadcast.playlists.first.air_date).to eq(playlist_2_air_date.to_s)
        end
      end

      it 'creates playlist songs' do # rubocop:disable RSpec/ExampleLength
        aggregate_failures do
          first_playlist_songs = broadcast.playlists.first.songs
          expect(first_playlist_songs.count).to eq(26)
          expect(first_playlist_songs.first).to have_attributes(
            title: 'Typical Girls',
            artist: Artist.find_by(name: 'The Slits'),
            duration: nil
          )

          second_playlist_songs = broadcast.playlists.second.songs
          expect(second_playlist_songs.count).to eq(33)
          expect(second_playlist_songs.first).to have_attributes(
            title: 'Stop Having Fun',
            artist: Artist.find_by(name: 'The Wimps'),
            duration: nil
          )
        end
      end

      it 'creates artists' do
        expect(Artist.count).to eq(57)
        artist = Artist.find_by(name: 'Bikini Kill')
        album = Album.find_by(title: 'Reject All American')
        aggregate_failures do
          expect(artist).to be_present
          expect(album).to be_present
          expect(artist.albums).to include(album)
          expect(album.artist).to eq(artist)
        end
      end
    end

    context 'when the start date is before the earliest playlist' do
      before do
        # scrape playlist 2 and 3
        described_class.new(broadcast, playlist_3_air_date, playlist_2_air_date).call
        broadcast.playlists.each { |p| p.playlist_import.destroy! }
      end

      # Now scrape playlists 1 and 2 so that 2 is scraped twice
      let(:start_date) { playlist_2_air_date }
      let(:end_date) { Time.zone.today }

      # it 'updates playlist 2 with new data' do
      #   # the script actually doesn't do this. Should it? Is there a reason to expect a historic playlist to change...
      #   # what if an initial scrape got incorrect or incomplete info? Test that.
      #   # TODO: test incomplete scraping
      #   # expect { call_task }.to change { broadcast.reload.playlists.second.scraped_data }.from(nil)
      # end

      it 'does not update playlist_3' do
        expect { call_task }.not_to change { broadcast.reload.playlists.first.scraped_data }.from(nil)
      end

      it 'scrapes playlist_1' do
        expect { described_class.new(broadcast, playlist_2_air_date, nil).call }
          .to change { broadcast.reload.playlists.count }.by(1)
        expect(broadcast.playlists.last).to have_attributes(
          title: 'Ballad of A Mix Tape',
          playlist_url: "#{base_url}/broadcasts/39512"
        )
      end
    end

    context 'when scraping without a start date' do
      let(:start_date) { nil }
      let(:end_date) { Date.new(2020, 10, 6).end_of_day }
      let(:call_task) { described_class.new(broadcast, start_date, end_date).call }

      before do
        # stub the url of the last playlist with playlist_11
        stub_request(:get, 'https://xray.fm/broadcasts/36506')
          .to_return(status: 200, body: playlist_11)
      end

      context 'when no playlists are found' do
        it 'starts scraping from the oldest playlist' do
          call_task
          expect(broadcast.reload.playlists.first.title).to eq('A Mellow Good Time')
        end
      end
    end

    context 'when scraping a playlist without songs listed' do
      let(:start_date) { playlist_4_no_songs_air_date }
      let(:end_date) { playlist_4_no_songs_air_date }

      before { call_task }

      it 'creates a playlist without songs' do
        expect(broadcast.playlists.count).to eq(1)
        expect(broadcast.playlists.first).to have_attributes(
          title: 'Stiff Competition redux - originally aired May 29, 2018',
          playlist_url: "#{base_url}/broadcasts/39197",
          original_playlist_id: nil,
          download_url_1: 'https://cdn.xray.fm/audio/strange-babes/Stiff_Competition_redux_2.mp3',
          download_url_2: nil
        )
        expect(broadcast.playlists.first.songs.count).to eq(0)
      end
    end

    context 'when scraping a playlist with two download links' do
      let(:start_date) { playlist_double_downloads_date }
      let(:end_date) { playlist_double_downloads_date }

      before { call_task }

      it 'creates a playlist with two download links' do
        expect(broadcast.playlists.count).to eq(1)
        expect(broadcast.playlists.first).to have_attributes(
          title: "Let's Get Down Together (EVERGREEN)",
          playlist_url: "#{base_url}/broadcasts/37486",
          download_url_1: 'https://cdn.xray.fm/audio/strange-babes/Let_sGetDownTogetherPartOne.mp3',
          download_url_2: 'https://cdn.xray.fm/audio/strange-babes/Let_sGetDownTogetherPartTwo.mp3'
        )
      end
    end

    context 'when scraping the same playlist twice' do
      let(:start_date) { playlist_1_air_date }

      before { call_task }

      it 'does not create duplicate playlists' do
        expect { call_task }.not_to change { broadcast.playlists.count }.from(1)
      end

      it 'does not create duplicate songs' do
        expect { call_task }.not_to change(Song, :count).from(33)
      end
    end

    context 'when scraping playlists that span two index pages' do
      # start on the most recent playlist of the second page, then scrape the first page
      let(:start_date) { playlist_11_air_date }

      before { call_task }

      it 'creates a playlist with songs' do
        expect(broadcast.playlists.count).to eq(11)
        expect(broadcast.playlists.first).to have_attributes(
          title: 'At Home In Strange Places',
          playlist_url: "#{base_url}/broadcasts/38446"
        )
        expect(broadcast.playlists.first.songs.count).to eq(28)
      end
    end
  end

  describe '#find_start_date_page_number' do
    let(:find_page) do
      described_class.new(broadcast, start_date).find_start_date_page_number(base_url, broadcast_name)
    end
    let(:page_1_first_date) { DateTime.new(2021, 4, 27) }
    let(:page_1_last_date) { DateTime.new(2021, 2, 23) }
    let(:page_2_first_date) { DateTime.new(2021, 2, 16) }
    let(:page_2_last_date) { DateTime.new(2020, 12, 8) }
    let(:page_3_first_date) { DateTime.new(2020, 12, 1) }
    let(:page_3_last_date) { DateTime.new(2020, 10, 6) }
    let(:first_xray_broadcast_date) { DateTime.new(2014, 3, 15) }

    context 'when the start date is before the earliest playlist' do
      let(:start_date) { first_xray_broadcast_date }

      it 'returns the page number of the last page' do
        expect(find_page).to eq(3)
      end
    end

    context 'when the start date is the last date on the second page' do
      let(:start_date) { page_2_last_date }

      it 'returns page number 2' do
        expect(find_page).to eq(2)
      end
    end

    context 'when the start date is before the earliest date on the second page' do
      let(:start_date) { page_2_last_date - 1.minute }

      it 'returns page number 3' do
        expect(find_page).to eq(3)
      end
    end

    context 'when the start date is the most recent date on the second page' do
      let(:start_date) { page_2_first_date }

      it 'returns page number 2' do
        expect(find_page).to eq(2)
      end
    end

    context 'when the start date between the second page and the third page' do
      let(:start_date) { page_3_first_date + 3.days }

      it 'returns page number 3' do
        expect(find_page).to eq(3)
      end
    end
  end

  describe '#open_broadcasts_index_page' do
    let(:page_number) { 1 }
    let(:page_content) { html_content_1 }
    let(:start_date) { nil }
    let(:task) { described_class.new(broadcast, start_date) }

    it 'fetches the page content when not cached' do
      task.open_broadcasts_index_page(base_url, broadcast_name, page_number).to_html

      expect(WebMock).to have_requested(
        :get, "#{base_url}/programs/#{broadcast_name}/page:#{page_number}?url=broadcasts%2F#{broadcast_name}"
      )
    end

    it 'retrieves the page content from cache on subsequent calls' do
      2.times { task.open_broadcasts_index_page(base_url, broadcast_name, page_number) }
      expect(WebMock).to have_requested(
        :get, "#{base_url}/programs/#{broadcast_name}/page:#{page_number}?url=broadcasts%2F#{broadcast_name}"
      ).once
    end
  end
end
