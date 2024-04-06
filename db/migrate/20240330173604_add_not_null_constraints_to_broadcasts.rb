# frozen_string_literal: true

class AddNotNullConstraintsToBroadcasts < ActiveRecord::Migration[7.1]
  def change
    change_column_null :broadcasts, :station_id, false
    change_column_null :broadcasts, :title, false
    change_column_null :broadcasts, :url, false
  end
end
