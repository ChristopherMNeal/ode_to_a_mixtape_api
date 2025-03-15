# frozen_string_literal: true

class AddNormalizedColumnsToVariousTables < ActiveRecord::Migration[7.1]
  def change
    add_column :albums,      :normalized_title, :string
    add_column :broadcasts,  :normalized_title, :string
    add_column :playlists,   :normalized_title, :string
    add_column :songs,       :normalized_title, :string

    add_column :artists,     :normalized_name,  :string
    add_column :genres,      :normalized_name,  :string
    add_column :record_labels, :normalized_name, :string

    add_index :albums,      :normalized_title
    add_index :broadcasts,  :normalized_title, unique: true
    add_index :playlists,   :normalized_title
    add_index :songs,       :normalized_title

    add_index :artists,     :normalized_name, unique: true
    add_index :genres,      :normalized_name, unique: true
    add_index :record_labels, :normalized_name, unique: true
  end
end
