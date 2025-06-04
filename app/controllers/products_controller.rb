class ProductsController < ApplicationController
    def index
        products = Product.includes(:categories).all
        render json: products, include: [ :categories ]
    end

    def create
    product = Product.new(product_params)
    if product.save
        render json: product, include: [ :categories ], status: :created
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

    def get_all_products
        items = Item.where(in_out: "in").where("last_qty > 0")
        mixed = Object.new
        id_arr = []
        item_arr = []
        items.each do |i|
            if !id_arr.include?(i.product_id)
                i.total = i.last_qty * i.price
                item_arr.push(i)
                id_arr.push(i.product_id)
            else
                item_arr.each do |a|
                    if a.product_id == i.product_id
                        a.last_qty += i.last_qty
                        a.total += i.last_qty * i.price
                        a.price = a.total / a.last_qty
                    end
                end
            end
        end
        mixed.instance_variable_set(:@products, item_arr)
        mixed.instance_variable_set(:@pre_sells, PreSell.all)
        mixed.instance_variable_set(:@pre_produce, PreProduce.where("pre_produce_status != 'inactive'"))
        render json: mixed, status: :ok
    end
end
