class CreateItemRelationships < ActiveRecord::Migration[8.0]
  def change
    create_table :item_relationships do |t|
      t.references :parent_item, null: false, foreign_key: {to_table: :items}
      t.references :child_item, null: false, foreign_key: {to_table: :items}
    end
  end
end
