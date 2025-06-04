class ReportsController < ApplicationController
    def buy_report
        @items = Item.includes(:product, :order)
                .where(item_type: "buy")
                .order(created_at: :desc)
                .limit(500)
        render json: @items.as_json(include: { order: { include: { customer: {} } }, product: { include: { categories: {} } } }), status: :ok
    end
    def sell_report
        @items = Item.includes(:product, :order)
                    .where(item_type: "sell")
                    .order(created_at: :desc)
                    .limit(500)
        render json: @items.as_json(include: { order: { include: { customer: {} } }, product: { include: { categories: {} } } }), status: :ok
    end
    def cash_report
        @orders = Order.includes(:customer)
                    .where.not(in_out: "not_applicable")

        render json: @orders.as_json(include: { customer: {} }), status: :ok
    end

    def production_report
        @orders = Order.includes(items: :product).where(order_type: "transferred")

        @orders.each do |o|
            total_in = 0.0
            total_out = 0.0

            # First pass: calculate total_in and total_out in VISS
            o.items.each do |i|
            p = i.product
            var = 1.0
            unit = ""

            p.categories.each do |c|
                var *= c.name.to_f if c.category_type == "variation"
                unit = c.name if c.category_type == "unit"
            end

            qty = i.qty.to_f * var
            qty_in_viss = convert_to_viss(qty, unit)

            if i.in_out == "in"
                total_in += qty_in_viss
            elsif i.in_out == "out"
                total_out += qty_in_viss
            end
            end

            # Second pass: assign yields
            o.items.each do |i|
            p = i.product
            var = 1.0
            unit = ""

            p.categories.each do |c|
                var *= c.name.to_f if c.category_type == "variation"
                unit = c.name if c.category_type == "unit"
            end

            qty = i.qty.to_f * var
            qty_in_viss = convert_to_viss(qty, unit) / 30.0

            i.yield = if i.in_out == "in"
                total_in > 0 ? (qty_in_viss / total_out).round(4) : 0
            else
                total_in_one = total_in / 30.0
                total_in > 0 ? (total_in_one / total_out).round(4) : 0
            end
            end
        end

        render json: @orders.as_json(include: {
            customer: {},
            items: {
            methods: [ :yield ],
            include: { product: {} }
            }
        }), status: :ok
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
