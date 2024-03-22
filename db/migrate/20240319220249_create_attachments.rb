class CreateAttachments < ActiveRecord::Migration[7.1]
  def change
    create_table :attachments do |t|
      t.string :reference_id, index: { unique: true }
      t.string :size

      t.timestamps
    end
  end
end
