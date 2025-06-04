class Order < ApplicationRecord
  has_many :items, dependent: :destroy
  belongs_to :customer
  has_many :parent_relationships, class_name: "OrderRelationship", foreign_key: :child_order_id, dependent: :destroy
  has_many :parents, through: :parent_relationships, source: :parent_order

  has_many :child_relationships, class_name: "OrderRelationship", foreign_key: :parent_order_id, dependent: :destroy
  has_many :children, through: :child_relationships, source: :child_order

  has_many :expense_categories_orders, dependent: :destroy
  has_many :expense_categories, through: :expense_categories_orders
  accepts_nested_attributes_for :items
end
