# frozen_string_literal: true

class CreatePlaylists < ActiveRecord::Migration[7.1]
  def change
    create_table :playlists do |t|
      t.string :title
      t.datetime :air_date
      t.references :station, foreign_key: true
      t.references :broadcast, foreign_key: true
      t.string :playlist_url
      t.integer :original_playlist_id
      t.string :download_url_1
      t.string :download_url_2
      t.jsonb :scraped_data

      t.timestamps
    end

    add_foreign_key :playlists, :playlists, column: :original_playlist_id, primary_key: :id
  end
end
