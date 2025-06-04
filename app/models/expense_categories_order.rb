class ExpenseCategoriesOrder < ApplicationRecord
    belongs_to :order
    belongs_to :expense_category
end