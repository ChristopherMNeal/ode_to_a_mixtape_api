# frozen_string_literal: true

class RemoveFirstBroadcastAtAndLastBroadcastAtFromBroadcasts < ActiveRecord::Migration[7.1]
  def change
    remove_column :broadcasts, :first_broadcast_at, :datetime # rubocop:disable Rails/BulkChangeTable
    remove_column :broadcasts, :last_broadcast_at, :datetime
  end
end
