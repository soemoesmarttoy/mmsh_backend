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

      Rails.logger.debug(pre_sell)

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
        pre_produces = PreProduce.where.not(pre_produce_status: "inactive")
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
          @pre_produce = PreProduce.find_by(id: pre[:id])
          @pre_produce.update(pre_produce_status: "inactive")

          @p1 = Product.find_by(id: @pre_produce.product_id)
          p_name = @p1.name

          # Filter out the "wet" category
          p_cats = @p1.categories.reject { |cat| cat.name == "wet" }

          # Add the "dried" category
          dried_cat = Category.find_by(name: "dried")
          desired_cats = p_cats + [ dried_cat ]

          # Find products with the same name
          products_with_same_name = Product.where(name: p_name)

          # Now select the one with the exact same categories (including dried, excluding wet)
          @p2 = products_with_same_name.find do |product|
            # Get category IDs (assuming `categories` is a has_many through association)
            product_cat_ids = product.categories.pluck(:id).sort
            desired_cat_ids = desired_cats.map(&:id).sort

            product_cat_ids == desired_cat_ids
          end
          unless @p2
            raise ActiveRecord::Rollback
            render json: { messages: @p2.erorrs.full_messages }, status: :unprocessable_entity
          end
          @new_one = PreProduce.create!(
            product_id: @p2.id,
            customer_id: @pre_produce.customer_id,
            temp_id: @pre_produce.temp_id,
            qty: @pre_produce.qty,
            in_out: "out",
            pre_produce_type: @pre_produce.pre_produce_type,
            pre_produce_status: "active"
          )
          unless @pre_produce.save
            raise ActiveRecord::Rollback
            render json: { messages: @pre_produce.erorrs.full_messages }, status: :unprocessable_entity
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
end
