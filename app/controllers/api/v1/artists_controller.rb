# frozen_string_literal: true

module Api
  module V1
    class ArtistsController < ApplicationController
      def index
        artists = Artist.order(:name).limit(50)
        render json: { artists: }
      end

      def show
        artist = Artist.includes(:songs, :albums).find(params[:id])
        render json: { artist: }, include: %w[songs albums]
      end

      def search
        query = params[:q]
        artists = if query
                    Artist.where('name ILIKE ?', "%#{query}%").limit(20)
                  else
                    Artist.order(:name).limit(20)
                  end
        render json: { artists: }
      end

      def playlists
        artist = Artist.find(params[:id])
        playlists = Playlist.joins(songs: :artist)
                            .where(songs: { artist_id: artist.id })
                            .distinct
                            .order(air_date: :desc)
                            .limit(20)
        render json: { playlists: }
      end
    end
  end
end
