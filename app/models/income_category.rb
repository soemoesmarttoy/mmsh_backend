class IncomeCategory < ApplicationRecord
    has_many :income_categories_orders
    has_many :orders, through: :income_categories_orders
end