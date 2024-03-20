# frozen_string_literal: true

class CreateStations < ActiveRecord::Migration[7.1]
  def change
    create_table :stations do |t|
      t.string :name
      t.string :call_sign
      t.string :city
      t.string :state
      t.string :base_url
      t.string :broadcasts_index_url
      t.string :phone_number
      t.string :text_number
      t.string :email
      t.jsonb :frequencies

      t.timestamps
    end
  end
end
