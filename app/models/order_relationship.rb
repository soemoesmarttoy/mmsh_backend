class OrderRelationship < ApplicationRecord
  belongs_to :parent_order, class_name: 'Order'
  belongs_to :child_order, class_name: 'Order'
end
