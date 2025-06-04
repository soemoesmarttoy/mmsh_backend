class Product < ApplicationRecord
    has_many :items
    has_and_belongs_to_many :categories
    def get_products_with_all_category_types(category_types)
        # Find products that have *all* the specified categories
        products = Product.joins(:categories)
                          .where(categories: { category_type: category_types })
                          .group("products.id")
                          .having("COUNT(DISTINCT categories.category_type) = ?", category_types.size)
                          .distinct

        products
    end
    has_many :pre_sells
end
