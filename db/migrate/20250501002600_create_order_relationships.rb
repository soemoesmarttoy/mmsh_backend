class CreateOrderRelationships < ActiveRecord::Migration[6.1]
  def change
    create_table :order_relationships do |t|
      t.references :parent_order, null: false, foreign_key: { to_table: :orders }
      t.references :child_order, null: false, foreign_key: { to_table: :orders }

      t.timestamps
    end
  end
end
