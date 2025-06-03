# frozen_string_literal: true

class RemoveUniqueConstraintFromBroadcastsNormalizedTitle < ActiveRecord::Migration[7.1]
  def change
    remove_index :broadcasts, :normalized_title
    add_index :broadcasts, :normalized_title, unique: false
  end
end
