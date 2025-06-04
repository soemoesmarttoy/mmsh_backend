class CreatePreSells < ActiveRecord::Migration[8.0]
  def change
    create_table :pre_sells do |t|
      t.references :customer, null: true, foreign_key: { to_table: :customers }, type: :bigint
      t.decimal :total_amount, precision: 25, scale: 10 # Better for monetary values
      t.decimal :qty, precision: 25, scale: 10 # Better for monetary values
      t.decimal :price, precision: 25, scale: 10 # Better for monetary values
      t.references :product, null: false, foreign_key: { to_table: :products}, type: :bigint
      t.timestamps
    end
  end
end
