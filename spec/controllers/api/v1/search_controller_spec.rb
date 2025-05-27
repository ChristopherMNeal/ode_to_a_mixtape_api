# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::SearchController, type: :controller do
  describe 'GET #index' do
    it 'returns matching results from all models' do
      artist = create(:artist, name: 'Test Artist')
      song = create(:song, title: 'Test Song', artist:)
      album = create(:album, title: 'Test Album')
      broadcast = create(:broadcast, title: 'Test Broadcast')

      get :index, params: { q: 'Test' }

      expect(response).to have_http_status(:success)
      json = response.parsed_body
      expect(json['artists'].first['id']).to eq(artist.id)
      expect(json['songs'].first['id']).to eq(song.id)
      expect(json['albums'].first['id']).to eq(album.id)
      expect(json['broadcasts'].first['id']).to eq(broadcast.id)
    end

    it 'returns error when query parameter is missing' do
      get :index

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body['error']).to eq('Search query required')
    end
  end

  describe 'GET #fuzzy' do
    it 'returns fuzzy matches for the specified model' do
      artist1 = create(:artist, name: 'James Brown')
      create(:artist, name: 'James Smith')

      allow(FuzzyFinder).to receive(:fuzzy_find).and_return([artist1])

      get :fuzzy, params: { q: 'James Brwn', model: 'artist' }

      expect(response).to have_http_status(:success)
      expect(FuzzyFinder).to have_received(:fuzzy_find).with(
        Artist, 'name', 'James Brwn', threshold: 0.6
      )
    end

    it 'returns error when query parameter is missing' do
      get :fuzzy, params: { model: 'artist' }

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body['error']).to eq('Search query required')
    end

    it 'returns error when model parameter is invalid' do
      get :fuzzy, params: { q: 'test', model: 'invalid_model' }

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body['error']).to eq('Invalid model')
    end
  end
end
