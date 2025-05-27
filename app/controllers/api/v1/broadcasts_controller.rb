# frozen_string_literal: true

module Api
  module V1
    class BroadcastsController < ApplicationController
      def index
        broadcasts = Broadcast.where(active: true)
                              .includes(:station)
                              .order(:title)
        render json: { broadcasts: }, include: ['station']
      end

      def show
        broadcast = Broadcast.includes(:station, :playlists, :dj).find(params[:id])
        json_response = {
          broadcast:,
          station: broadcast.station,
          playlists: broadcast.playlists,
          dj: broadcast.dj
        }
        render json: json_response
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Broadcast not found' }, status: :not_found
      end

      def by_station
        broadcasts = Broadcast.where(station_id: params[:station_id])
                              .order(:title)
        render json: { broadcasts: }
      end

      def by_day
        day = params[:day].to_i
        broadcasts = Broadcast.where(air_day: day)
                              .includes(:station)
                              .order(:air_time_start)
        render json: { broadcasts: }, include: ['station']
      end
    end
  end
end
