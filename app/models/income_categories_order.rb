class IncomeCategoriesOrder < ApplicationRecord
    belongs_to :order
    belongs_to :income_category
end