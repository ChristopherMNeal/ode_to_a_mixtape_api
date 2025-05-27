# frozen_string_literal: true

module Api
  module V1
    class SearchController < ApplicationController
      def index
        query = params[:q]
        return render json: { error: 'Search query required' }, status: :bad_request unless query

        results = {
          artists: Artist.where('name ILIKE ?', "%#{query}%").limit(5),
          songs: Song.includes(:artist).where('title ILIKE ?', "%#{query}%").limit(5),
          albums: Album.includes(:artist).where('title ILIKE ?', "%#{query}%").limit(5),
          broadcasts: Broadcast.where('title ILIKE ?', "%#{query}%").limit(5)
        }
        render json: results
      end

      def fuzzy
        query = params[:q]
        return render_error('Search query required') unless query

        column = params[:column] || 'name'
        threshold = params[:threshold]&.to_f || 0.6
        model = get_model_from_param(params[:model])

        return render_error('Invalid model') unless model

        results = FuzzyFinder.fuzzy_find(model, column, query, threshold:)
        render json: { results: }
      end

      private

      def render_error(message)
        render json: { error: message }, status: :bad_request
      end

      def get_model_from_param(model_name)
        return nil unless model_name

        begin
          model = model_name.classify.constantize
          model.is_a?(Class) ? model : nil
        rescue NameError
          nil
        end
      end
    end
  end
end
