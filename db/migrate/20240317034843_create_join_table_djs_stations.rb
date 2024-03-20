# frozen_string_literal: true

class CreateJoinTableDjsStations < ActiveRecord::Migration[7.1]
  def change
    create_table :djs_stations do |t|
      t.references :dj, null: false, foreign_key: true
      t.references :station, null: false, foreign_key: true
      t.string :profile_url

      t.timestamps
    end
  end
end
