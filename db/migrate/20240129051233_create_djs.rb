# frozen_string_literal: true

class CreateDjs < ActiveRecord::Migration[7.1]
  def change
    create_table :djs do |t|
      t.string :dj_name
      t.string :member_names
      t.text :bio
      t.string :email
      t.string :twitter
      t.string :instagram
      t.string :facebook

      t.timestamps
    end
  end
end
