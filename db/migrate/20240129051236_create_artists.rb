# frozen_string_literal: true

class CreateArtists < ActiveRecord::Migration[7.1]
  def change
    create_table :artists do |t|
      t.string :name
      t.text :bio

      t.timestamps
    end
  end
end
