class ExpenseCategory < ApplicationRecord
    has_many :expense_categories_orders
    has_many :orders, through: :expense_categories_orders
end