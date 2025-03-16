# frozen_string_literal: true

class RemoveScrapedDataFromPlaylists < ActiveRecord::Migration[7.1]
  def change
    remove_column :playlists, :scraped_data # rubocop:disable Rails/ReversibleMigration
  end
end
