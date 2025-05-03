class ItemRelationship < ApplicationRecord
  belongs_to :parent_order, class_name: 'Item'
  belongs_to :child_order, class_name: 'Item'
end
