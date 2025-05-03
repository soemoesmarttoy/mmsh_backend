class CustomersController < ApplicationController
    def index
        customers = Customer.all
        render json: customers
    end

    def create
        customer = Customer.new(customer_params)
        if customer.save
            render json: customer, status: :created
        else
            render json: { errors: customer.errors.full_messages }, status: :unprocessable_entity
        end
    end

    def update
    end

    def delete
    end

    def customer_params
        params.require(:customer).permit(:name)
    end
end
