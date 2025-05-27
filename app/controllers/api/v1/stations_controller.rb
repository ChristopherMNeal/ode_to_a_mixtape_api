# frozen_string_literal: true

module Api
  module V1
    class StationsController < ApplicationController
      def index
        stations = Station.all
        render json: { stations: }
      end

      def show
        station = Station.includes(:broadcasts).find(params[:id])
        json_response = {
          station:,
          broadcasts: station.broadcasts
        }
        render json: json_response
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Station not found' }, status: :not_found
      end
    end
  end
end
