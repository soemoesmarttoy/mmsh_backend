class AddFieldsToItemRelationships < ActiveRecord::Migration[8.0]
  def change
    add_column :item_relationships, :qty, :decimal, precision: 25, scale:10
    add_column :item_relationships, :price, :decimal, precision: 25, scale:10
  end
end
