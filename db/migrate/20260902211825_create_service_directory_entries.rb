class CreateServiceDirectoryEntries < ActiveRecord::Migration[7.2]
  def change
    create_table :service_directory_entries, id: :uuid do |t|
      t.string :name, null: false
      t.string :icon_asset, null: false
      t.string :brand_color
      t.string :cancellation_url
      t.string :region, null: false, default: "global"
      t.references :default_category, null: false, foreign_key: { to_table: :categories }, type: :uuid

      t.timestamps
    end
  end
end
