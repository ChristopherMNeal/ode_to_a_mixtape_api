# frozen_string_literal: true

module Api
  module V1
    class PlaylistsController < ApplicationController
      include PlaylistFinder
      def index
        playlists = Playlist.includes(:broadcast, :station)
                            .where(original_playlist_id: nil)
                            .order(air_date: :desc)
                            .limit(20)
        render json: { playlists: }, include: %w[broadcast station]
      end

      def show
        playlist = Playlist.includes(:songs, :broadcast, :station).find(params[:id])
        render json: {
          playlist:,
          songs: playlist.songs,
          broadcast: playlist.broadcast,
          station: playlist.station
        }
      end

      def by_broadcast
        playlists = Playlist.where(broadcast_id: params[:broadcast_id])
                            .order(air_date: :desc)
        render json: { playlists: }
      end

      def by_date
        start_date = Date.parse(params[:start_date])
        end_date = params[:end_date] ? Date.parse(params[:end_date]) : Time.zone.today
        playlists = Playlist.where(air_date: start_date.beginning_of_day..end_date.end_of_day)
                            .order(air_date: :desc)
        render json: { playlists: }
      end

      # Get a random playlist
      def random
        playlist = Playlist.where(original_playlist_id: nil).order('RANDOM()').first
        render json: {
          playlist:,
          songs: playlist.songs,
          broadcast: playlist.broadcast,
          station: playlist.station
        }
      end

      # Find playlists containing a specific artist or song
      def find
        return render_param_error unless valid_search_params?

        playlists = find_playlists_by_params
        render json: { playlists: }
      end

      def valid_search_params?
        params[:artist_id].present? || params[:song_id].present?
      end

      def render_param_error
        render json: { error: 'artist_id or song_id parameter required' }, status: :bad_request
      end

      def find_playlists_by_params
        if params[:artist_id].present?
          find_playlists_by_artist(params[:artist_id])
        else
          find_playlists_by_song(params[:song_id])
        end
      end

      # Find playlists from the same date in previous years
      def on_this_day
        month, day = extract_date_params

        return render_date_error(:month) unless valid_month?(month)
        return render_date_error(:day) unless valid_day?(day)

        playlists = find_playlists_for_date(month, day)
        render_on_this_day_response(playlists, month, day)
      end

      def extract_date_params
        today = Time.zone.today
        month = extract_param(:month, today.month)
        day = extract_param(:day, today.day)
        [month, day]
      end

      def extract_param(param_name, default)
        params[param_name].present? ? params[param_name].to_i : default
      end

      def valid_month?(month)
        (1..12).include?(month)
      end

      def valid_day?(day)
        (1..31).include?(day)
      end

      def render_date_error(type)
        render json: { error: "Invalid #{type} value" }, status: :bad_request
      end

      def render_on_this_day_response(playlists, month, day)
        render json: {
          playlists:,
          date_info: {
            month:,
            day:,
            month_name: Date::MONTHNAMES[month],
            date_description: "#{Date::MONTHNAMES[month]} #{day}"
          }
        }
      end
    end
  end
end
