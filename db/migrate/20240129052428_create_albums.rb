# frozen_string_literal: true

class CreateAlbums < ActiveRecord::Migration[7.1]
  def change
    create_table :albums do |t|
      t.string :title
      t.date :release_date
      t.references :artist, foreign_key: true
      t.references :genre, foreign_key: true
      t.references :record_label, foreign_key: true

      t.timestamps
    end
  end
end
