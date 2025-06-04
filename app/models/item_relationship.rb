class ItemRelationship < ApplicationRecord
  belongs_to :parent_item, class_name: "Item", optional: true
  belongs_to :child_item, class_name: "Item"

  # No unnecessary has_many here either
end
