# frozen_string_literal: true

class CreateSongs < ActiveRecord::Migration[7.1]
  def change
    create_table :songs do |t|
      t.string :title
      t.integer :duration
      t.references :artist, foreign_key: true
      t.references :genre, foreign_key: true
      # t.integer :spotify_id
      # t.integer :youtube_id
      # t.integer :soundcloud_id
      # t.integer :bandcamp_id
      # t.integer :apple_music_id
      # t.integer :amazon_music_id
      # t.integer :google_play_music_id
      # t.integer :tidal_id
      # t.integer :deezer_id
      # t.integer :last_fm_id
      # t.integer :discogs_id
      # t.integer :music_brainz_id
      # t.integer :all_music_id

      t.timestamps
    end
    add_index :songs, :title
  end
end
