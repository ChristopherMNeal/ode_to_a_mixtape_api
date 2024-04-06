# frozen_string_literal: true

class AddThemeToPlaylists < ActiveRecord::Migration[7.1]
  def change
    add_column :playlists, :theme, :string
    add_column :playlists, :holiday, :string

    add_index :playlists, :theme
    add_index :playlists, :holiday
  end
end
