class CreateTerms < ActiveRecord::Migration
  def change
    create_table :terms do |t|
      t.string :scraped_id
      t.string :name

      t.timestamps null: false
    end
    add_index :terms, :scraped_id, unique: true
  end
end
