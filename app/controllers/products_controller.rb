class ProductsController < ApplicationController
    def index
        products = Product.includes(:categories).all
        render json: products, include: [:categories]
    end

    def create
    product = Product.new(product_params)
    if product.save
        render json: product, include: [:categories], status: :created
    else
        render json: { errors: product.errors.full_messages }, status: :unprocessable_entity
    end
    end

    def update
    end

    def delete
    end

    
    def product_params
        params.require(:product).permit(
            :name, 
            :pcode,
            category_ids: []    
            )
    end
end
