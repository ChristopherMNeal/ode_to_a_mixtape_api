# frozen_string_literal: true

class ChangeNormalizedIndexesOnVariousTables < ActiveRecord::Migration[7.1]
  def change # rubocop:disable Metrics
    # Update songs table: enforce uniqueness by artist_id and title / normalized_title
    remove_index :songs, :title if index_exists?(:songs, :title)
    remove_index :songs, :normalized_title if index_exists?(:songs, :normalized_title)
    add_index :songs, %i[artist_id title], unique: true, name: 'index_songs_on_artist_id_and_title'
    add_index :songs, %i[artist_id normalized_title], unique: true,
                                                      name: 'index_songs_on_artist_id_and_normalized_title'

    # Update albums table: enforce uniqueness by artist_id and title / normalized_title
    remove_index :albums, :title if index_exists?(:albums, :title)
    remove_index :albums, :normalized_title if index_exists?(:albums, :normalized_title)
    add_index :albums, %i[artist_id title], unique: true, name: 'index_albums_on_artist_id_and_title'
    add_index :albums, %i[artist_id normalized_title], unique: true,
                                                       name: 'index_albums_on_artist_id_and_normalized_title'

    # Update broadcasts table: remove unique constraint on normalized_title
    remove_index :broadcasts, :normalized_title if index_exists?(:broadcasts, :normalized_title)
    add_index :broadcasts, :normalized_title, unique: false

    # Add unique constraints to other tables while we're at it
    remove_index :broadcasts, :url if index_exists?(:broadcasts, :url)
    change_column_null :broadcasts, :url, false
    add_index :broadcasts, :url, unique: true

    remove_index :playlists, :playlist_url if index_exists?(:playlists, :playlist_url)
    change_column_null :playlists, :playlist_url, false
    add_index :playlists, 'LOWER(playlist_url)', unique: true, name: 'index_playlists_on_lower_playlist_url'

    remove_index :stations, :name if index_exists?(:stations, :name)
    change_column_null :stations, :name, false
    add_index :stations, :name, unique: true
    remove_index :stations, :base_url if index_exists?(:stations, :base_url)
    change_column_null :stations, :base_url, false
    add_index :stations, :base_url, unique: true
    remove_index :stations, :broadcasts_index_url if index_exists?(:stations, :broadcasts_index_url)
    change_column_null :stations, :broadcasts_index_url, false
    add_index :stations, :broadcasts_index_url, unique: true
    remove_index :stations, :call_sign if index_exists?(:stations, :call_sign)
    add_index :stations, :call_sign, unique: true
  end
end
