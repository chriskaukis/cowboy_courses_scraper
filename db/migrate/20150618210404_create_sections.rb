class CreateSections < ActiveRecord::Migration
  def change
    create_table :sections do |t|
      t.string :name
      t.string :scraped_id
      t.references :term, index: true, foreign_key: true
      t.references :course, index: true, foreign_key: true
      t.string :call_number
      t.index :call_number
      t.string :status
      t.index :status
      t.integer :open_seats
      t.integer :total_seats
      # MWF, TR, MTWRF, etc.
      t.string :days
      # Times the section starts.
      t.datetime :starts_at
      t.datetime :ends_at
      # Dates the section starts.
      t.datetime :starts_on
      t.datetime :ends_on
      t.timestamps null: false
    end
  end
end
