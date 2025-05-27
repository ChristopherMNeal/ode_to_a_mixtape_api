# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Playlists', type: :request do
  let!(:station) { create(:station) }
  let!(:broadcast) { create(:broadcast, station:) }
  let!(:artist) { create(:artist, name: 'Test Artist') }
  let!(:song) { create(:song, artist:, title: 'Test Song') }
  let!(:recent_playlist) { create(:playlist, broadcast:, station:, air_date: 1.day.ago) }
  let!(:older_playlist) { create(:playlist, broadcast:, station:, air_date: 2.days.ago) }
  let!(:oldest_playlist) { create(:playlist, broadcast:, station:, air_date: 3.days.ago) }
  let!(:playlist_song) { create(:playlists_song, playlist: recent_playlist, song:) }

  # Add a playlist with a specific date for on_this_day test
  let(:may_27_last_year) { Date.new(2024, 5, 27) }
  let!(:may_27_playlist) { create(:playlist, air_date: may_27_last_year) }

  describe 'GET /api/v1/playlists' do
    it 'returns a list of recent playlists' do
      get '/api/v1/playlists'

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to have_key('playlists')
      expect(response.parsed_body['playlists']).to be_an(Array)
    end
  end

  describe 'GET /api/v1/playlists/:id' do
    it 'returns a single playlist with its associations' do
      get "/api/v1/playlists/#{recent_playlist.id}"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to have_key('playlist')
      expect(response.parsed_body['songs']).to be_an(Array)
      expect(response.parsed_body['broadcast']).to be_present
      expect(response.parsed_body['station']).to be_present
    end
  end

  describe 'GET /api/v1/playlists/random' do
    it 'returns a random playlist with its associations' do
      get '/api/v1/playlists/random'

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to have_key('playlist')
      expect(response.parsed_body['songs']).to be_an(Array)
      expect(response.parsed_body['broadcast']).to be_present
      expect(response.parsed_body['station']).to be_present
    end
  end

  describe 'GET /api/v1/playlists/find' do
    context 'with artist_id parameter' do
      it 'returns playlists featuring the artist' do
        get '/api/v1/playlists/find', params: { artist_id: artist.id }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to have_key('playlists')
        expect(response.parsed_body['playlists']).to be_an(Array)
        expect(response.parsed_body['playlists'].length).to be > 0
      end
    end

    context 'with song_id parameter' do
      it 'returns playlists featuring the song' do
        get '/api/v1/playlists/find', params: { song_id: song.id }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to have_key('playlists')
        expect(response.parsed_body['playlists']).to be_an(Array)
        expect(response.parsed_body['playlists'].length).to be > 0
      end
    end

    context 'without required parameters' do
      it 'returns a bad request error' do
        get '/api/v1/playlists/find'

        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body).to have_key('error')
      end
    end
  end

  describe 'GET /api/v1/playlists/on_this_day' do
    context 'with month and day parameters' do
      it 'returns playlists from the specified date across years' do
        # Use a date we know has a playlist
        get '/api/v1/playlists/on_this_day', params: { month: 5, day: 27 }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to have_key('playlists')
        expect(response.parsed_body['playlists']).to be_an(Array)

        # Should include our may_27_playlist
        playlist_ids = response.parsed_body['playlists'].map { |p| p['id'] }
        expect(playlist_ids).to include(may_27_playlist.id)

        # Should include date information
        expect(response.parsed_body).to have_key('date_info')
        expect(response.parsed_body['date_info']).to include(
          'month' => 5,
          'day' => 27,
          'month_name' => 'May',
          'date_description' => 'May 27'
        )
      end
    end

    context 'without parameters' do
      it 'returns playlists from today across years' do
        get '/api/v1/playlists/on_this_day'

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to have_key('playlists')
        expect(response.parsed_body['playlists']).to be_an(Array)
        expect(response.parsed_body).to have_key('date_info')
      end
    end

    context 'with invalid parameters' do
      it 'returns bad request for invalid month' do
        get '/api/v1/playlists/on_this_day', params: { month: 13, day: 1 }

        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body).to have_key('error')
      end

      it 'returns bad request for invalid day' do
        get '/api/v1/playlists/on_this_day', params: { month: 5, day: 32 }

        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body).to have_key('error')
      end
    end
  end
end
