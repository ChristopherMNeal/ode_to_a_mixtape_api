# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::SongsController, type: :controller do
  describe 'GET #index' do
    it 'returns the latest 50 songs with artists' do
      create_list(:song, 60) # rubocop:disable RSpec/ExcessiveCreateList

      get :index

      expect(response).to have_http_status(:success)
      songs = response.parsed_body['songs']
      expect(songs.length).to eq(50)
    end
  end

  describe 'GET #show' do
    it 'returns song with its associations' do
      song = create(:song)
      album = create(:album)
      playlist = create(:playlist)
      song.albums << album
      song.playlists << playlist

      get :show, params: { id: song.id }

      expect(response).to have_http_status(:success)
      json = response.parsed_body
      expect(json['song']['id']).to eq(song.id)
      expect(json).to have_key('artist')
      expect(json).to have_key('albums')
      expect(json).to have_key('playlists')
    end

    it 'returns 404 for non-existent song' do
      get :show, params: { id: 999 }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET #search' do
    it 'returns matching songs when query is provided' do
      matching_song = create(:song, title: 'Find Me')
      non_matching_song = create(:song, title: 'Skip Me') # rubocop:disable Lint/UselessAssignment

      get :search, params: { q: 'Find' }

      expect(response).to have_http_status(:success)
      songs = response.parsed_body['songs']
      expect(songs.length).to eq(1)
      expect(songs.first['id']).to eq(matching_song.id)
    end

    it 'returns latest songs when no query is provided' do
      create_list(:song, 25) # rubocop:disable RSpec/ExcessiveCreateList

      get :search

      expect(response).to have_http_status(:success)
      songs = response.parsed_body['songs']
      expect(songs.length).to eq(20)
    end
  end
end
