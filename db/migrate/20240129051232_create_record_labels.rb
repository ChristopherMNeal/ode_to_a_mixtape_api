# frozen_string_literal: true

class CreateRecordLabels < ActiveRecord::Migration[7.1]
  def change
    create_table :record_labels do |t|
      t.string :name

      t.timestamps
    end
  end
end
