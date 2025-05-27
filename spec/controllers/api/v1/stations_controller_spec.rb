# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::StationsController, type: :controller do
  describe 'GET #index' do
    it 'returns all stations' do
      create_list(:station, 3)

      get :index

      expect(response).to have_http_status(:success)
      stations = response.parsed_body['stations']
      expect(stations.length).to eq(3)
    end
  end

  describe 'GET #show' do
    it 'returns station with its broadcasts' do
      station = create(:station)
      broadcasts = create_list(:broadcast, 2, station:) # rubocop:disable Lint/UselessAssignment

      get :show, params: { id: station.id }

      expect(response).to have_http_status(:success)
      json = response.parsed_body
      expect(json['station']['id']).to eq(station.id)
      expect(json).to have_key('broadcasts')
      expect(json['broadcasts'].length).to eq(2)
    end

    it 'returns 404 for non-existent station' do
      get :show, params: { id: 999 }

      expect(response).to have_http_status(:not_found)
    end
  end
end
