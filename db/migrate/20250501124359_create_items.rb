class CreateItems < ActiveRecord::Migration[8.0]
  def change
    create_table :items do |t|
      t.references :product, null: false, foreign_key: true
      t.decimal :price, precision: 25, scale: 10
      t.decimal :qty, precision: 25, scale: 10
      t.string :in_out
      t.string :item_type
      t.belongs_to :order, index: true, foreign_key: true
      t.decimal :last_qty, precision: 25, scale: 10
      t.timestamps
    end
  end
end
