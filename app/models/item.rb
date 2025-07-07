class Item < ApplicationRecord
  attr_accessor :total
  attr_accessor :custom_yield
  belongs_to :product
  belongs_to :order
  has_many :child_relationships, class_name: "ItemRelationship", foreign_key: :parent_item_id, dependent: :destroy
  has_many :children, through: :child_relationships, source: :child_item

  has_many :parent_relationships, class_name: "ItemRelationship", foreign_key: :child_item_id, dependent: :destroy
  has_many :parents, through: :parent_relationships, source: :parent_item
end
