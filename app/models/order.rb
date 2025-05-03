class Order < ApplicationRecord
  belongs_to :customer, optional: true
  has_many :items, dependent: :destroy
  has_many :child_relationships, class_name: 'OrderRelationship', foreign_key: 'parent_order_id', dependent: :destroy
  has_many :children, through: :child_relationships, source: :child_order

  # parent orders
  has_many :parent_relationships, class_name: 'OrderRelationship', foreign_key: 'child_order_id', dependent: :destroy
  has_many :parents, through: :parent_relationships, source: :parent_order

  accepts_nested_attributes_for :items
end
