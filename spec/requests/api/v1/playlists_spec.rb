# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Playlists' do
  describe 'GET /index' do
    pending 'returns http success' do
      get '/api/v1/playlists/index'
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /broadcast' do
    pending 'returns http success' do
      get '/api/v1/playlists/broadcast'
      expect(response).to have_http_status(:success)
    end
  end
end
