class CreateItems < ActiveRecord::Migration[8.0]
  def change
    create_table :items do |t|
      t.references :product, null: false, foreign_key: true
      t.decimal :price, precision:15, scale: 2
      t.decimal :qty, precision: 15, scale: 2
      t.decimal :last_total, precision:15, scale: 2
      t.string :in_out
      t.string :item_type
      t.belongs_to :order, index: true, foreign_key: true
      t.timestamps
    end
  end
end
