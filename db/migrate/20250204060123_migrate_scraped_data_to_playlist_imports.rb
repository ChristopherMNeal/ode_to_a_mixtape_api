# frozen_string_literal: true

class MigrateScrapedDataToPlaylistImports < ActiveRecord::Migration[7.1]
  def up
    Playlist.find_each do |playlist|
      PlaylistImport.create!(
        playlist_id: playlist.id,
        scraped_data: playlist.scraped_data
      )
    end
  end

  def down
    PlaylistImport.delete_all
  end
end
