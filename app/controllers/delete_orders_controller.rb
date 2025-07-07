class DeleteOrdersController < ApplicationController
  def delete_buy
    ActiveRecord::Base.transaction do
      @order = Order.find_by(id: params[:id])
      if @order.items.length > 0
        @order.items.each do |i|
          if i.qty != i.last_qty
            render json: { messages: "failed" }
            return
          end
        end
        @order.items.each do |i|
          i.delete
        end
      end
      if @order.parents && @order.parents.any?
        @order.parents.each do |p|
          if p.parents.any?
            p.parents.each do |p1|
              p1.last_total += p.total_amount
              unless p1.save
                ActiveRecord::Rollback
                render json: { messages: "error: cannot find parent orders" }
                return
              end
              @child = OrderRelationship.find_by(child_order_id: p.id)
              @parent = OrderRelationship.find_by(parent_order_id: p.id)
              @child.delete
              @parent.delete
              p.delete
            end
          else
            ActiveRecord::Rollback
            render json: { messages: "error: cannot find parent orders" }
            return
          end
        end
      end
      @order.delete
      render json: { messages: "success" }
    end
  end

  def delete_production
    ActiveRecord::Base.transaction do
      @order = Order.find_by(id: params[:id])
      unless @order
        render json: { messages: "failed", error: "Order not found" }, status: :not_found
        raise ActiveRecord::Rollback
      end

      if @order.items.any?
        @order.items.each do |i|
          if i.qty != i.last_qty && i.in_out == "in"
            render json: { messages: "failed" }
            raise ActiveRecord::Rollback
          end
        end
        @order.items.where(in_out: "out").each do |i|
          ItemRelationship.where(parent_item_id: i.id).destroy_all
          @parent = i.parents[0]
          if @parent
            @parent.last_qty += i.qty
            unless @parent.last_qty <= @parent.qty && @parent.save
              raise ActiveRecord::Rollback
              render json: { messages: "failed" }
              return
            end
          else
            raise ActiveRecord::Rollback
            render json: { messages: "failed" }
            return
          end
        end

        @order.items.each(&:destroy)
        @order.destroy
        render json: { messages: "success" }
      else
        render json: { messages: "failed" }
        raise ActiveRecord::Rollback
      end
    end
  end


  def delete_sell
    @order = Order.find_by(id: params[:id])
    ActiveRecord::Base.transaction do
      if @order.children.any?
        @order.children.each do |c|
          if c.last_total != c.total_amount
            render json: { messages: "failed" }
            return
          end
        end
        @order.children.each do |c|
          unless c.destroy
            Rails.logger.error "Failed to destroy child order ##{c.id}: #{c.errors.full_messages.join(", ")}"
            raise ActiveRecord::Rollback
            render json: { messages: "failed" }
            return
          end
        end
      end
      if @order.items.any?
        @order.items.each do |i|
          if i.parents.any?
            i.parents.each do |p|
              pr = ItemRelationship.find_by(parent_item_id: p.id, child_item_id: i.id)
              if pr
                p.last_qty += pr[:qty]
                unless p.last_qty <= p.qty && p.save
                  ActiveRecord::Rollback
                  render json: { messages: "failed" }
                  return
                end
                pr.delete
              else
                ActiveRecord::Rollback
                render json: { messages: "failed" }
                return
              end
            end
          else
            ActiveRecord::Rollback
            render json: { messages: "failed" }
            return
          end
          i.delete
        end
      else
        ActiveRecord::Rollback
        render json: { messages: "failed" }
        return
      end
      @order.delete
      render json: { messages: "success" }
    end
  end
end
