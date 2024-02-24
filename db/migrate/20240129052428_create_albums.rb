# frozen_string_literal: true

class CreateAlbums < ActiveRecord::Migration[7.1]
  def change
    create_table :albums do |t|
      t.string :title
      t.date :release_date
      t.integer :artist_id
      t.integer :genre_id
      t.integer :record_label_id

      t.timestamps
    end
  end
end
