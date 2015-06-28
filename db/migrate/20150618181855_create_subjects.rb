class CreateSubjects < ActiveRecord::Migration
  def change
    create_table :subjects do |t|
      t.string :scraped_id
      t.string :name

      t.timestamps null: false
    end
  end
end
