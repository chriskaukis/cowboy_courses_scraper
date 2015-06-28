class CreateCourses < ActiveRecord::Migration
  def change
    create_table :courses do |t|
      t.string :scraped_id
      t.string :name
      t.references :subject, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
