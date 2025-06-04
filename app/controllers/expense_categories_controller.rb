class ExpenseCategoriesController < ApplicationController
    def index
        @expense_categories = ExpenseCategory.all
        render json: @expense_categories
    end
    def create
        @expense_category = ExpenseCategory.create!(
            name: params[:expense_category][:name]
        )
        unless @expense_category
            render json: { messages: @expense_category.errors.full_messages }, status: :unprocessable_entity
        end
        render json: @expense_category, status: :ok
    end

    def expsense_categories_params
        params.require(:expense_cateogry)
            .permit(
                :expense_category_id,
                :amt,
                :cash,
                :name
            )
    end

    def create_expense
        ActiveRecord::Base.transaction do
            parents = params[:order][:parent_orders]
            amt = params[:order][:total_amount].to_f
            @child = Order.create!(
                total_amount: amt,
                order_type: "spent",
                in_out: "out",
                customer_id: params[:order][:customer_id],
                last_total: amt,
            )
            unless @child
                raise ActiveRecord::Rollback
                render json: {messages: @child.erorrs.full_messages}, status: :unprocessable_entity
            end
            ExpenseCategoriesOrder.create!(
                order: @child,
                expense_category_id: params[:order][:expense_category_id]
            )
            remaining_to_deduct = amt
            parents.each do |p|
                @parent = Order.find_by(id: p[:id])
                unless @parent
                    raise ActiveRecord::Rollback
                    render json: {messages: @parent.erorrs.full_messages}, status: :unprocessable_entity
                end
                balance = [remaining_to_deduct, @parent.last_total].min
                @parent.last_total -= balance
                unless @parent.last_total >= 0 && @parent.save
                    raise ActiveRecord::Rollback
                    render json: {messages: @parent.erorrs.full_messages}, status: :unprocessable_entity
                end
                OrderRelationship.create!(
                    parent_order: @parent,
                    child_order: @child
                )
            end
        end
    end
end