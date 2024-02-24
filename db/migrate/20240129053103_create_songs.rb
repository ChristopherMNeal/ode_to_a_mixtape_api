# frozen_string_literal: true

class CreateSongs < ActiveRecord::Migration[7.1]
  def change
    create_table :songs do |t|
      t.string :title
      t.integer :duration
      t.integer :album_id
      t.integer :genre_id

      t.timestamps
    end
  end
end
