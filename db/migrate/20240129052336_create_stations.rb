# frozen_string_literal: true

class CreateStations < ActiveRecord::Migration[7.1]
  def change
    create_table :stations do |t|
      t.string :name
      t.string :call_sign
      t.string :location

      t.timestamps
    end
  end
end
