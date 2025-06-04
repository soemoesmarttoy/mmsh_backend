class CreateExpenseCategoriesOrdersJoinTable < ActiveRecord::Migration[8.0]
  def change
    create_join_table :orders, :expense_categories do |t|
      t.index [:order_id, :expense_category_id]
      t.index [:expense_category_id, :order_id]
    end
    create_join_table :orders, :income_categories do |t|
      t.index [:order_id, :income_category_id]
      t.index [:income_category_id, :order_id]
    end
  end
end
