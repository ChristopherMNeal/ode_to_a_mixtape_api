# frozen_string_literal: true

class AddFundDriveToPlaylists < ActiveRecord::Migration[7.1]
  def change
    add_column :playlists, :fund_drive, :boolean, default: false, null: false
  end
end
