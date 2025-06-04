class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.string :order_type
      t.references :customer, null: true, foreign_key: { to_table: :customers }, type: :bigint
      t.string :in_out
      t.decimal :total_amount, precision: 25, scale: 10 # Better for monetary values
      t.decimal :last_total, precision: 25, scale: 10
      t.timestamps
    end
  end
end
