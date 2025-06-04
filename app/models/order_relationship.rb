class OrderRelationship < ApplicationRecord
  belongs_to :parent_order, class_name: "Order", optional: true
  belongs_to :child_order, class_name: "Order"

  # No need for has_many here — keep it simple
end
