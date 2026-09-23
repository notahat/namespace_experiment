class CreateCatalogBooks < ActiveRecord::Migration[8.1]
  def change
    create_table :catalog_books do |t|
      t.string :title, null: false
      t.references :author, null: false, foreign_key: { to_table: :catalog_authors }
      t.date :published_on

      t.timestamps
    end
  end
end
