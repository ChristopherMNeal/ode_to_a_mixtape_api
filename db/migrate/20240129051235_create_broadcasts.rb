# frozen_string_literal: true

class CreateBroadcasts < ActiveRecord::Migration[7.1]
  def change
    create_table :broadcasts do |t|
      t.references :station, foreign_key: true
      t.references :dj, foreign_key: true
      t.string :title
      t.string :old_title
      t.string :url
      t.integer :air_day, null: true
      t.time :air_time_start
      t.time :air_time_end
      t.boolean :active, default: true
      t.datetime :last_scraped_at
      t.datetime :last_broadcast_at
      t.datetime :first_broadcast_at
      t.integer :frequency_in_days

      t.timestamps
    end
    add_check_constraint :broadcasts, 'air_day IS NULL OR (air_day >= 0 AND air_day <= 6)', name: 'air_day_valid_range'
    add_index :broadcasts, :title
  end
end
