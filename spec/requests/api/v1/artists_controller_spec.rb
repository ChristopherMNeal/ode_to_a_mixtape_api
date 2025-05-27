# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::ArtistsController, type: :request do
  let!(:artist) { create(:artist) }
  let!(:song) { create(:song, artist:) }
  let!(:album) { create(:album, artist:) }
  let!(:playlist) { create(:playlist) }
  let!(:playlist_song) { create(:playlists_song, playlist:, song:) }

  describe 'GET /api/v1/artists' do
    it 'returns a list of artists' do
      get '/api/v1/artists'
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['artists']).to be_an(Array)
    end
  end

  describe 'GET /api/v1/artists/:id' do
    it 'returns a single artist with songs and albums' do
      get "/api/v1/artists/#{artist.id}"
      expect(response).to have_http_status(:ok)
      json = response.parsed_body['artist']
      expect(json['id']).to eq(artist.id)
      expect(json['songs']).to be_an(Array)
      expect(json['albums']).to be_an(Array)
    end
  end

  describe 'GET /api/v1/artists/search' do
    it 'returns artists matching the query' do
      get '/api/v1/artists/search', params: { q: artist.name }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['artists']).to be_an(Array)
    end
  end

  describe 'GET /api/v1/artists/:id/playlists' do
    it 'returns playlists featuring the artist' do
      get "/api/v1/artists/#{artist.id}/playlists"
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['playlists']).to be_an(Array)
    end
  end
end
