# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::BroadcastsController, type: :controller do
  describe 'GET #index' do
    it 'returns active broadcasts ordered by title' do
      create(:broadcast, active: true, title: 'B Show')
      create(:broadcast, active: true, title: 'A Show')
      inactive_broadcast = create(:broadcast, active: false)

      get :index

      expect(response).to have_http_status(:success)
      broadcasts = response.parsed_body['broadcasts']
      expect(broadcasts.length).to eq(2)
      expect(broadcasts.first['title']).to eq('A Show')
      expect(broadcasts.map { |b| b['id'] }).not_to include(inactive_broadcast.id)
    end
  end

  describe 'GET #show' do
    it 'returns broadcast with its associations' do
      broadcast = create(:broadcast)

      get :show, params: { id: broadcast.id }

      expect(response).to have_http_status(:success)
      json = response.parsed_body
      expect(json['broadcast']['id']).to eq(broadcast.id)
      expect(json).to have_key('station')
      expect(json).to have_key('playlists')
      expect(json).to have_key('dj')
    end

    it 'returns 404 for non-existent broadcast' do
      get :show, params: { id: 999 }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET #by_station' do
    it 'returns broadcasts filtered by station' do
      station = create(:station)
      station_broadcast = create(:broadcast, station:)
      other_broadcast = create(:broadcast) # rubocop:disable Lint/UselessAssignment

      get :by_station, params: { station_id: station.id }

      expect(response).to have_http_status(:success)
      broadcasts = response.parsed_body['broadcasts']
      expect(broadcasts.length).to eq(1)
      expect(broadcasts.first['id']).to eq(station_broadcast.id)
    end
  end

  describe 'GET #by_day' do
    it 'returns broadcasts for specific day ordered by air time' do
      monday_early = create(:broadcast, air_day: 1, air_time_start: '08:00')
      monday_late = create(:broadcast, air_day: 1, air_time_start: '20:00')
      tuesday = create(:broadcast, air_day: 2) # rubocop:disable Lint/UselessAssignment

      get :by_day, params: { day: 1 }

      expect(response).to have_http_status(:success)
      broadcasts = response.parsed_body['broadcasts']
      expect(broadcasts.length).to eq(2)
      expect(broadcasts.first['id']).to eq(monday_early.id)
      expect(broadcasts.last['id']).to eq(monday_late.id)
    end
  end
end
