class OrdersController < ApplicationController
    def index
        orders = Order.all
        render json: orders
    end

    def create
        order = Order.new(order_params.except(:parent_order_ids)) 
        if order.save
            if params[:order][:parent_order_ids].present?
                parent_ids = params[:order][:parent_order_ids].reject(&:blank?)
                remaining_amount = order.total_amount.to_f
            
                parent_ids.each do |pid|
                break if remaining_amount <= 0
            
                OrderRelationship.create!(
                    parent_order_id: pid,
                    child_order_id: order.id
                )
            
                parent_order = Order.find_by(id: pid)
                next unless parent_order
            
                parent_last = parent_order.last_total.to_f
            
                if parent_last >= remaining_amount
                    parent_order.update!(last_total: parent_last - remaining_amount)
                    remaining_amount = 0
                else
                    parent_order.update!(last_total: 0)
                    remaining_amount -= parent_last
                end
                end
            end
        
            render json: order, status: :created
        else
            render json: { errors: order.errors.full_messages }, status: :unprocessable_entity
        end
    end
      

    def update
    end

    def delete
    end

    def get_cash_balance
        orders = Order.joins(:customer)
                  .where(in_out: 'in')
                  .where("last_total > 0")

        render json: orders, include: :customer

    end

    def order_params
        params.require(:order).permit(
          :total_amount,
          :in_out,
          :customer_id,
          :order_type,
          :last_total,
          parent_order_ids: [],
          items_attributes: [
            :product_id,
            :qty,
            :price,
            :item_type,
            :in_out,
            :last_total
          ]
        )
    end
end
