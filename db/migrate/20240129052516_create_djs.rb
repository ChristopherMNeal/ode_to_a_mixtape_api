# frozen_string_literal: true

class CreateDjs < ActiveRecord::Migration[7.1]
  def change
    create_table :djs do |t|
      t.string :name
      t.text :bio

      t.timestamps
    end
  end
end
