# frozen_string_literal: true

module Api
  module V1
    class SongsController < ApplicationController
      def index
        songs = Song.includes(:artist).order(created_at: :desc).limit(50)
        render json: { songs: }, include: ['artist']
      end

      def show
        song = Song.includes(:artist, :albums, :playlists).find(params[:id])
        json_response = {
          song:,
          artist: song.artist,
          albums: song.albums,
          playlists: song.playlists
        }
        render json: json_response
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Song not found' }, status: :not_found
      end

      def search
        query = params[:q]
        songs = if query
                  Song.includes(:artist)
                      .where('songs.title ILIKE ?', "%#{query}%")
                      .limit(20)
                else
                  Song.includes(:artist).order(created_at: :desc).limit(20)
                end
        render json: { songs: }, include: ['artist']
      end
    end
  end
end
