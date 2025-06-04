class CreateCustomers < ActiveRecord::Migration[8.0]
  def change
    create_table :customers do |t|
      t.string :name
    end
    reversible do |dir|
      dir.up do
        Customer.reset_column_information
        Customer.create!(name: "main")
      end
    end
  end
end
