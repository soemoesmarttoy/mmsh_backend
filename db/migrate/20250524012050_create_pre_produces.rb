class CreatePreProduces < ActiveRecord::Migration[8.0]
  def change
    create_table :pre_produces do |t|
      t.references :customer, null: true, foreign_key: { to_table: :customers }, type: :bigint
      t.references :product, null: false, foreign_key: { to_table: :products }, type: :bigint
      t.string :pre_produce_type
      t.string :pre_produce_status
      t.decimal :qty, precision: 25, scale: 10 # Better for monetary values
      t.bigint :temp_id
      t.string :in_out
      t.timestamps
    end
  end
end
