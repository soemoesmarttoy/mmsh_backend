class OrdersController < ApplicationController
    def index
        orders = Order.all
        render json: orders
    end

    def get_order_by_id
      order = Order.includes(:customer, items: { product: [ :categories ] }).find_by(id: params[:order_id])

      if order
        order.items.each do |item|
          rs = ItemRelationship.where(child_item_id: item.id)
          item.parents = rs
        end

        render json: order.as_json(
          include: {
            customer: {},
            items: {
              include: {
                product: { include: :categories }
              },
              methods: [ :parents ] # 👈 this includes your dynamic attribute
            }
          }
        ), status: :ok
      else
        render json: { errors: [ "Order not found" ] }, status: :unprocessable_entity
      end
    end

    def create_production_order
      require "bigdecimal"
      require "bigdecimal/util"

      ActiveRecord::Base.transaction do
        clean_params = order_params.deep_dup.to_h
        clean_params[:items_attributes].each { |item| item.except!(:total, :parent_item_ids) }

        @order = Order.new(clean_params)
        unless @order.save
          render json: { errors: @order.errors.full_messages }, status: :unprocessable_entity
          raise ActiveRecord::Rollback
        end
        total_input = BigDecimal("0")
        total_output = BigDecimal("0")
        inputs = params[:order][:items_attributes][0][:parent_item_ids]
        input_arr = []
        inputs.each do |input|
          input[:inputIdArr].each do |i|
            total_input += BigDecimal(i[:qty].to_s) * BigDecimal(i[:price].to_s)
            @oldItem = Item.find_by(id: i[:id])
            @oldItem.last_qty -= i[:qty]
            unless @oldItem.last_qty >= 0 && @oldItem.save
              render json: { errors: @oldItem.errors.full_messages }, status: :unprocessable_entity
              raise ActiveRecord::Rollback
            end
            Rails.logger.debug(i)
            new_parent = Item.create!(
              product_id: @oldItem.product_id,
              qty: i[:qty],
              price: i[:price],
              last_qty: 0,
              in_out: "out",
              order_id: @order.id,
              item_type: "production"
            )
            ItemRelationship.create!(
              parent_item: @oldItem,
              child_item: new_parent,
              qty: i[:qty],
              price: i[:price]
            )
            input_arr.push(new_parent)
          end
        end
        @order.items.where(in_out: "in").each do |i|
          total_output += i.qty.to_d * i.price.to_d
          input_arr.each do |each|
            ItemRelationship.create!(
              parent_item: each,
              child_item: i,
              qty: each.qty,
              price: each.price
            )
          end
        end
        diff = total_input - total_output
        if diff != 0
          @order.items[0].price = (@order.items[0].price.to_d * @order.items[0].qty.to_d + diff) / @order.items[0].qty.to_d
          unless @order.save
            render json: { errors: @order.errors.full_messages }, status: :unprocessable_entity
            raise ActiveRecord::Rollback
          end
        end
      end
    end
    def get_to_pay_orders
      orders = Order.includes(:customer).where(order_type: "to_pay").where("last_total > 0")
      render json: orders.as_json(include: { customer: {} })
    end
    def get_to_receive_orders
      orders = Order.includes(:customer).where(order_type: "to_receive").where("last_total > 0")
      render json: orders.as_json(include: { customer: {} })
    end

    def settle_to_pay
      ActiveRecord::Base.transaction do
        child_orders = params[:order][:child_orders]
        parent_orders = params[:order][:parent_orders]
        updated_parents = []
        remaining_to_deduct = params[:order][:total_amount].to_f
        parent_orders.each do |p|
          parent_order = Order.find_by(id: p)
          unless parent_order
            render json: { erorrs: parent.erorrs.full_messages }, status: :unprocessable_entity
            raise ActiveRecord::Rollback
          end
          balance = [ parent_order.last_total, remaining_to_deduct ].min
          parent_order.last_total -= balance
          unless parent_order.last_total >= 0 && parent_order.save
            render json: { erorrs: parent_order.erorrs.full_messages }, status: :unprocessable_entity
            raise ActiveRecord::Rollback
          end
          remaining_to_deduct -= balance
          updated_parents.push(parent_order)
        end
        unless remaining_to_deduct === 0
            render json: { erorrs: "remaining amt to deduct from parent orders should be zero" }, status: :unprocessable_entity
            raise ActiveRecord::Rollback
        end

        child_orders.each do |p|
          child = Order.find_by(id: p[:id])
          unless child
            render json: { erorrs: child.erorrs.full_messages }, status: :unprocessable_entity
            raise ActiveRecord::Rollback
          end
          if p[:settledAmt].to_f > child[:last_total].to_f
            render json: { erorrs: "settled amt > actaul amt" }, status: :unprocessable_entity
            raise ActiveRecord::Rollback
          end
          child.last_total -= p[:settledAmt].to_f
          unless child.last_total >= 0 && child.save
            render json: { erorrs: "actual amt < 0" }, status: :unprocessable_entity
            raise ActiveRecord::Rollback
          end
          @order = Order.create!(
            customer_id: child.customer_id,
            total_amount: p[:settledAmt].to_f,
            order_type: "paid",
            in_out: "out",
            last_total: 0
          )
          updated_parents.each do |p|
            OrderRelationship.create!(
              parent_order: p,
              child_order: @order,
            )
          end
          OrderRelationship.create!(
            child_order: child,
            parent_order: @order,
          )
        end
        render json: { messages: "success" }, status: :ok
      end
    end
    def settle_to_receive
      ActiveRecord::Base.transaction do
        child_params = params[:order][:child_orders]
        remaining_to_deduct = params[:order][:total_amount].to_f
        child_params.each do |c|
          @child = Order.find_by(id: c[:id])
          unless @child
            render json: { errors: @child.errors.full_messages }, status: :unprocessable_entity
            raise ActiveRecord::Rollback
          end
          balance = [ @child.last_total, remaining_to_deduct ].min
          @child.last_total -= balance
          unless @child.last_total >= 0 && @child.save
            render json: { errors: @child.errors.full_messages }, status: :unprocessable_entity
            raise ActiveRecord::Rollback
          end
          @parent = Order.create!(
            customer_id: params[:order][:customer_id],
            total_amount: balance,
            order_type: "received",
            in_out: "in",
            last_total: balance,
          )
          unless @parent
            render json: { errors: @parent.errors.full_messages }, status: :unprocessable_entity
            raise ActiveRecord::Rollback
          end
          OrderRelationship.create!(
            parent_order: @parent,
            child_order: @child
          )
          remaining_to_deduct -= balance
        end
        unless remaining_to_deduct === 0
          render json: { errors: "remaining amt to deduct should be zero" }, status: :unprocessable_entity
          raise ActiveRecord::Rollback
        end
        render json: { messages: "success" }, status: :ok
      end
    end
    def create
      ActiveRecord::Base.transaction do
        @order = Order.new(order_params)
        unless @order.save
          render json: { errors: @order.errors.full_messages }, status: :unprocessable_entity
          raise ActiveRecord::Rollback
        end
        if params[:order][:parent_order_ids].present?
          parent_ids = params[:order][:parent_order_ids].reject(&:blank?)
          parent_orders = Order.where(id: parent_ids)
          total_to_deduct = @order.last_total.to_f
          remaining_to_deduct = total_to_deduct
          parent_orders.each do |parent|
            parent_balance = parent.last_total.to_f
            next if parent_balance <= 0
            used_amount = [ remaining_to_deduct, parent_balance ].min
            OrderRelationship.create!(parent_order: parent, child_order: @order)
            parent.update!(
              last_total: normalize_zero(parent_balance - used_amount)
            )
            remaining_to_deduct -= used_amount
            break if remaining_to_deduct <= 0
          end
        end
        total = 0
        @order.items.each_with_index do |item, index|
          item_params = params[:order][:items_attributes][index]
          parent_item_ids = item_params[:parent_item_ids] || []
          parent_item_ids.reject!(&:blank?)
          remaining_qty = item.last_qty.to_f
          total += BigDecimal(item.last_qty.to_s) * BigDecimal(item.price.to_s)
          parent_item_ids.each do |pid|
            parent_item = Item.find_by(id: pid)
            next unless parent_item && parent_item.last_qty.to_f > 0
            parent_last_qty = parent_item.last_qty.to_f
            parent_qty = parent_item.qty.to_f
            next if parent_qty <= 0
            unit_price = parent_item.price
            used_qty = [ remaining_qty, parent_last_qty ].min
            parent_item.update!(
              last_qty: normalize_zero(parent_last_qty - used_qty),
            )
            ItemRelationship.create!(
              parent_item: parent_item,
              child_item: item,
              qty: used_qty,
              price: parent_item.price
            )
            remaining_qty -= used_qty
            break if remaining_qty <= 0
          end
          @order.total_amount = total
          @order.last_total = total
          unless @order.save
            render json: { errors: @order.errors.full_messages }, status: :unprocessable_entity
            raise ActiveRecord::Rollback
          end
        end
        render json: @order, status: :created
      end
    end


    def normalize_zero(value, epsilon = 0.015)
        (value.abs < epsilon) ? 0.0 : value
    end

    def update
    end

    def delete
    end

    def get_cash_balance
        orders = Order.includes(:customer)
                  .where(in_out: "in")
                  .where("last_total > 0")
        if orders
            render json: orders, include: :customer
        else
            render json: { error: "Cash Orders not found" }, status: :not_found
        end
    end

    def get_product_balance
      items = Item.includes(:order, product: [ :categories ])
                .where(product_id: params[:product_id], in_out: "in")
                .where("last_qty > 0")
      if items.any?
        render json: items.as_json(
          include: {
            order: { include: { customer: {} } },
            product: {
              include: {
                categories: {}
              }
            }
          }
        )
      else
        render json: { error: "No items found" }, status: :not_found
      end
    end
    def order_params
      permitted_items = [
        :product_id, :qty, :price, :item_type, :in_out, :last_qty
      ]

      # Add these only for production orders
      if action_name == "create_production_order" || params[:order][:order_type] == "transferred"
        permitted_items += [ parent_item_ids: [ :id, :qty, :price ] ]
      end

      params.require(:order).permit(
        :total_amount, :in_out, :customer_id, :order_type, :last_total,
        items_attributes: permitted_items
      )
    end
end
