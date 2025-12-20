class PreSellsController < ApplicationController
    def create
        pre_sell = PreSell.create!(
            pre_sell_params
        )
        unless pre_sell
            render json: { erorrs: pre_sell.error.messages }, status: :unprocessable_entity
        end
        render json: pre_sell, status: :ok
    end
    def get_pre_sells
        render json: PreSell.all, status: :ok
    end
    def rent_collect
      ActiveRecord::Base.transaction do
        amt = params[:order][:total_amount].to_f
        @child = Order.create!(
            total_amount: amt,
            order_type: "earned",
            in_out: "in",
            customer_id: params[:order][:customer_id],
            last_total: amt,
        )
        unless @child
            raise ActiveRecord::Rollback
            render json: { messages: @child.erorrs.full_messages }, status: :unprocessable_entity
        end
        IncomeCategoriesOrder.create!(
            order: @child,
            income_category_id: params[:order][:income_category_id]
        )
        pre_produces = params[:order][:preProduces]
        pre_produces.each do |pre|
          @pre_produce = PreProduce.find_by(id: pre[:id])
          @pre_produce.pre_produce_status = "rent_collected"
          unless @pre_produce.save
            raise ActiveRecord::Rollback
            render json: { messages: @pre_produce.erorrs.full_messages }, status: :unprocessable_entity
          end
        end
      end
    end
    def settle
      pre_sells = params[:pre_sell][:pre_sells]
      pre_sell = pre_sells.first
      selected_items = params[:pre_sell][:selectedItems]
      ActiveRecord::Base.transaction do
        @order = Order.create!(
          order_type: "to_receive",
          in_out: "not_applicable",
          customer_id: pre_sell[:customer_id],
          total_amount: BigDecimal(pre_sell[:total_amount]),
          last_total: BigDecimal(pre_sell[:total_amount]),
          created_at: pre_sell[:updated_at],
        )

        @item = Item.create!(
          product_id: pre_sell[:product_id],
          in_out: "out",
          item_type: "sell",
          qty: pre_sell[:qty],
          price: pre_sell[:price],
          last_qty: pre_sell[:qty],
          order_id: @order.id,
          created_at: pre_sell[:created_at]
        )

        to_deduct_qty = pre_sell[:qty].to_f

        selected_items.each do |item|
          qty = [ item[:last_qty].to_f, to_deduct_qty ].min
          next if qty <= 0

          org_item = Item.find_by(id: item[:id])
          unless org_item
            render json: { errors: [ "Item not found with ID #{item[:id]}" ] }, status: :unprocessable_entity
            raise ActiveRecord::Rollback
          end

          org_item.last_qty -= qty
          unless org_item.save
            render json: { errors: org_item.errors.full_messages }, status: :unprocessable_entity
            raise ActiveRecord::Rollback
          end

          ItemRelationship.create!(
            parent_item: org_item,
            child_item: @item,
            qty: qty,
            price: item[:price].to_s.gsub(/[^\d.]/, "").to_f
          )

          to_deduct_qty -= qty
        end

        @pre_sell = PreSell.find_by(id: pre_sell[:id])
        unless @pre_sell&.destroy
          render json: { errors: [ "Failed to delete PreSell with ID #{pre_sell[:id]}" ] }, status: :unprocessable_entity
          raise ActiveRecord::Rollback
        end
      end
    end

    def update_pre_produce
      ActiveRecord::Base.transaction do
        id = params[:ids]
        if id != nil
          id.each do |i|
            @pre_produce = PreProduce.find_by(id: i)
            @pre_produce.pre_produce_status = "inactive"
            unless @pre_produce.save
              ActiveRecord::Rollback
              render json: { errors: [ @pre_produce.erorrs.messages ] }, status: :unprocessable_entity
            end
          end
        end
      end
      render json: { messages: [ "success" ] }, status: :ok
    end

    def get_pre_produce
      temp_id = params[:temp_id]
      Rails.logger.debug(params)
      Rails.logger.debug(temp_id)
      if temp_id != nil
        pre_produces = PreProduce.where(temp_id: temp_id)
      else
        pre_produces = PreProduce.where.not(pre_produce_status: [ "inactive", "withdrawn" ])
      end
      render json: pre_produces, status: :ok
    end

    def rent_buy
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
        temp_id = params[:order][:tempId]
        @pre_produces = PreProduce.where(temp_id: temp_id)
        @pre_produces.each do |pre|
          pre.pre_produce_status = "inactive"
          unless pre.save
            raise ActiveRecord::Rollback
            render json: { errors: pre.errors.full_messages }, status: :unprocessable_entity
          end
        end
        render json: @order, status: :created
      end
    end

def withdrawn_list
  pre_sells = PreProduce
    .includes(:customer, product: :categories)
    .where(pre_produce_status: "withdrawn")
    .order(updated_at: :desc)
    .limit(500)

  # 1. First Pass: Calculate Batch Totals
  batch_metrics = {}
  pre_sells.group_by(&:temp_id).each do |temp_id, items|
    t_in = 0.0
    t_out_normalized = 0.0

    items.each do |i|
      # Extract variation and unit
      v = i.product.categories.find { |c| c.category_type == "variation" }&.name.to_f || 1.0
      u = i.product.categories.find { |c| c.category_type == "unit" }&.name || ""
      
      if i.in_out == "out"
        t_in += i.qty.to_f
      else
        # Formula: (Qty * Variation / 30)
        t_out_normalized += (i.qty.to_f * v) / 30.0
      end
    end

    batch_metrics[temp_id] = { 
      total_in: t_in, 
      total_out_norm: t_out_normalized,
      batch_yield: t_in > 0 ? (t_out_normalized / t_in * 100).round(2) : 0
    }
  end

  # 2. Second Pass: Format each row
  formatted_results = pre_sells.map do |item|
    metrics = batch_metrics[item.temp_id]
    
    # Calculate this specific item's normalized value
    item_v = item.product.categories.find { |c| c.category_type == "variation" }&.name.to_f || 1.0
    item_norm = (item.qty.to_f * item_v) / 30.0

    # Apply specific logic per row type
    display_yield = 0.0
    if metrics[:total_in] > 0
      if item.in_out == "out"
        # Paddy Row -> Show the Total Batch Yield (Total Out Norm / Total In)
        display_yield = metrics[:batch_yield]
      else
        # Out Row -> Show Item Share (This Item Norm / Total In)
        display_yield = (item_norm / metrics[:total_in] * 100).round(2)
      end
    end

    item.as_json(include: { customer: {}, product: { include: :categories } }).merge({
      "calculated_yield" => display_yield,
      "batch_total_in" => metrics[:total_in],
      "batch_total_out_norm" => metrics[:total_out_norm]
    })
  end

  render json: formatted_results, status: :ok
end
    private

    # Helper to handle the repetition of category/viss logic
    def calc_viss(item)
      variation = 1.0
      unit_name = ""
      item.product.categories.each do |cat|
        variation *= cat.name.to_f if cat.category_type == "variation"
        unit_name = cat.name if cat.category_type == "unit"
      end
      convert_to_viss(item.qty.to_f * variation, unit_name)
    end

    def rent_dried_collect
      ActiveRecord::Base.transaction do
        amt = params[:order][:total_amount].to_f
        @child = Order.create!(
            total_amount: amt,
            order_type: "earned",
            in_out: "in",
            customer_id: params[:order][:customer_id],
            last_total: amt,
        )
        unless @child
            raise ActiveRecord::Rollback
            render json: { messages: @child.erorrs.full_messages }, status: :unprocessable_entity
        end
        IncomeCategoriesOrder.create!(
            order: @child,
            income_category_id: params[:order][:income_category_id]
        )
        pre_produces = params[:order][:preProduces]
        pre_produces.each do |pre|
          if pre[:in_out] == "out"
            @pre_produce = PreProduce.find_by(id: pre[:id])
            @pre_produce.update(pre_produce_status: "inactive")
          else
            @pre_produce = PreProduce.find_by(id: pre[:id])
            @pre_produce.update(pre_produce_status: "inactive")
            PreProduce.create!(
              customer_id: @pre_produce.customer_id,
              product_id: @pre_produce.product_id,
              pre_produce_type: "rent",
              pre_produce_status: "active",
              qty: @pre_produce.qty,
              temp_id: params[:order][:new_temp_id],
              in_out: "out",
            )
          end
        end
      end
    end

    def get_product_balance_by_many
      items = Item.includes(:order, product: [ :categories ])
        .where(product_id: params[:product_ids], in_out: "in")
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


    def pre_sell_params
        params.require(:pre_sell)
        .permit(:customer_id, :product_id, :qty, :price, :total_amount)
    end

    def pre_produce
      failed_items = []

      items_params.each do |item|
        record = PreProduce.new(item)
        unless record.save
          failed_items << { errors: record.errors.full_messages, item: item }
        end
      end

      if failed_items.any?
        render json: { success: false, failed: failed_items }, status: :unprocessable_entity
      else
        render json: { success: true }
      end
    end

    def delete
      id = params[:temp_id]
      @pre_produces = PreProduce.where(temp_id: id)
      @pre_produces.each do |p|
        p.delete
      end
      render json: { success: true }
    end
    def withdrawn
      id = params[:temp_id]
      temp_id = params[:new_temp_id]
      @pre_produces = PreProduce.where(temp_id: id)
      @pre_produces.each do |pre_produce|
        pre_produce.update(pre_produce_status: "inactive")
        PreProduce.create!(
          customer_id: pre_produce.customer_id,
          product_id: pre_produce.product_id,
          pre_produce_type: "rent",
          pre_produce_status: "withdrawn",
          qty: pre_produce.qty,
          temp_id: temp_id,
          in_out: pre_produce.in_out,
        )
      end
      render json: { success: true }, status: :ok
    end
    def delete_pre_sell
      @pre_sell = PreSell.find_by(id: params[:id])
      unless @pre_sell.destroy
        render json: { messages: "failed" }
      end
      render json: { messages: "success" }
    end

    def delete_pre_produce
      @pre_produce = PreProduce.where(temp_id: params[:temp_id])
      unless @pre_produce.destroy_all
        render json: { messages: "failed" }
      end
      render json: { messages: "success" }
    end

    private


    def items_params
      params.require(:items).map do |item|
        item.permit(:in_out, :product_id, :qty, :pre_produce_status, :temp_id, :customer_id, :pre_produce_type)
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
    
    require "ruby-units"
    def convert_to_viss(qty, unit)
        return qty if ![ "mcg", "mg", "g", "kg", "mt", "oz", "lb", "t" ].include?(unit.downcase)
            begin
                kg = Unit("#{qty} #{unit}").to("kg").scalar
                kg / 0.612
            rescue
                0
        end
    end
end
