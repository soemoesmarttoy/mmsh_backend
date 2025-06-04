class IncomeCategoriesController < ApplicationController
    def index
        @income_categories = IncomeCategory.all
        render json: @income_categories
    end
    def create
        @income_category = IncomeCategory.create!(
            name: params[:income_category][:name]
        )
        unless @income_category
            render json: { messages: @income_category.errors.full_messages }, status: :unprocessable_entity
        end
        render json: @income_category, status: :ok
    end

    def income_categories_params
        params.require(:income_cateogry)
            .permit(
                :income_category_id,
                :amt,
                :cash,
                :name
            )
    end

    def create_income
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
                render json: {messages: @child.erorrs.full_messages}, status: :unprocessable_entity
            end
            IncomeCategoriesOrder.create!(
                order: @child,
                income_category_id: params[:order][:income_category_id]
            )
        end
    end
end