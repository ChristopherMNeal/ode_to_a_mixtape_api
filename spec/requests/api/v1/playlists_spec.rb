# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Playlists', type: :request do
  describe 'GET /index' do
    it 'returns http success' do
      get '/api/v1/playlists/index'
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /broadcast' do
    it 'returns http success' do
      get '/api/v1/playlists/broadcast'
      expect(response).to have_http_status(:success)
    end
  end
end
