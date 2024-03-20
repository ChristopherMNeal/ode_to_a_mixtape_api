# frozen_string_literal: true

class CreateAlbumsSongs < ActiveRecord::Migration[7.1]
  def change
    create_table :albums_songs do |t|
      t.references :album, null: false, foreign_key: true
      t.references :song, null: false, foreign_key: true
      t.integer :track_number

      t.timestamps
    end
  end
end
