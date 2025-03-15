# frozen_string_literal: true

class CreatePlaylistImports < ActiveRecord::Migration[7.1]
  def change
    create_table :playlist_imports do |t|
      t.references :playlist, null: false, foreign_key: true
      t.jsonb :scraped_data, default: {}

      t.timestamps
    end
  end
end
