# frozen_string_literal: true

module ApiRoutes
  def self.draw(mapper)
    mapper.namespace :api do
      mapper.namespace :v1 do
        draw_playlist_routes(mapper)
        draw_artist_routes(mapper)
        draw_song_routes(mapper)
        draw_broadcast_routes(mapper)
        draw_station_routes(mapper)
        draw_search_routes(mapper)
      end
    end
  end

  def self.draw_playlist_routes(mapper)
    mapper.resources :playlists, only: %i[index show] do
      mapper.collection do
        mapper.get 'by_broadcast/:broadcast_id', to: 'playlists#by_broadcast', as: :by_broadcast
        mapper.get 'by_date', to: 'playlists#by_date'
        mapper.get 'random', to: 'playlists#random'
        mapper.get 'find', to: 'playlists#find'
        mapper.get 'on_this_day', to: 'playlists#on_this_day'
      end
    end
  end

  def self.draw_artist_routes(mapper)
    mapper.resources :artists, only: %i[index show] do
      mapper.collection do
        mapper.get 'search', to: 'artists#search'
      end
      mapper.member do
        mapper.get 'playlists', to: 'artists#playlists'
      end
    end
  end

  def self.draw_song_routes(mapper)
    mapper.resources :songs, only: %i[index show] do
      mapper.collection do
        mapper.get 'search', to: 'songs#search'
      end
    end
  end

  def self.draw_broadcast_routes(mapper)
    mapper.resources :broadcasts, only: %i[index show] do
      mapper.collection do
        mapper.get 'by_station/:station_id', to: 'broadcasts#by_station', as: :by_station
        mapper.get 'by_day/:day', to: 'broadcasts#by_day', as: :by_day
      end
    end
  end

  def self.draw_station_routes(mapper)
    mapper.resources :stations, only: %i[index show]
  end

  def self.draw_search_routes(mapper)
    mapper.get 'search', to: 'search#index'
    mapper.get 'fuzzy_search', to: 'search#fuzzy'
  end
end
