class CreateBlobs < ActiveRecord::Migration[7.1]
  def change
    create_table :blobs do |t|
      t.references :attachment, null: false, foreign_key: true, index: true
      t.json :data
      t.integer :store_type, null: false, limit: 1

      t.timestamps
    end
  end
end
