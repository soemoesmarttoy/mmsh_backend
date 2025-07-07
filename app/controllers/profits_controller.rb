class ProfitsController < ApplicationController
    def get_profits
        from = params[:from]
        to = params[:to]
        sell_orders = Order.where(created_at: from..to)
                    .where(order_type: "to_receive")
        sell_total = sell_orders.sum(:total_amount)
        sell_orders = sell_orders.includes(items: :parents)
        cogs_total = 0
        sell_orders.each do |order|
            order.items.each do |item|
                item.parent_relationships.each do |p|
                    cogs_total += BigDecimal(p[:price].to_s) * BigDecimal(p[:qty].to_s)
                end
            end
        end
        expense = Order.where(created_at: from..to)
                    .where(order_type: "spent")
        expense_total = expense.sum(:total_amount)
        income = Order.where(created_at: from..to)
                    .where(order_type: "earned")
        income_total = income.sum(:total_amount)
        to1 = DateTime.parse(to)
        from1 = DateTime.parse(from)
        now = DateTime.now()
        diff = (now - to1).to_i
        diff_from = (now - from1).to_i
        start_of_day = diff_from.days.ago.beginning_of_day
        end_of_day = diff.days.ago.end_of_day
        orders = Order.where(created_at: ..end_of_day)

        equity_total = orders.where(order_type: "cash_added").sum(:total_amount) -
                        orders.where(order_type: "cash_withdrawn").sum(:total_amount)
        cash_total = orders.where(in_out: "in").sum(:last_total)
        inv_total =  Item.where(in_out: "in").sum(Arel.sql("last_qty * price"))
        rec_total = Order.where(created_at: ..end_of_day)
                        .where(order_type: "to_receive").sum(:last_total)
        pay_total = Order.where(created_at: ..end_of_day)
                        .where(order_type: "to_pay").sum(:last_total)
        sell_orders_from = Order.where(created_at: ..start_of_day)
                            .where(order_type: "to_receive")
        sell_orders_total_from = sell_orders_from.sum(:total_amount)
        cogs_total_from = 0
        sell_orders_from.each do |order_from|
            order_from.items.each do |item_from|
                item_from.parent_relationships.each do |p_from|
                    cogs_total_from += BigDecimal(p_from[:price].to_s) * BigDecimal(p_from[:qty].to_s)
                end
            end
        end
        expense_total_from = Order.where(created_at: ..start_of_day)
                    .where(order_type: "spent").sum(:total_amount)
        income_total_from = Order.where(created_at: ..start_of_day)
                    .where(order_type: "earned").sum(:total_amount)
        net_profit_from = BigDecimal(sell_orders_total_from.to_s) - cogs_total_from - BigDecimal(expense_total_from.to_s) + BigDecimal(income_total_from.to_s)
        item_in_before = Item.where(created_at: ..start_of_day).where(in_out: "in")
        item_out_before = Item.where(created_at: ..start_of_day).where(in_out: "out")
        out_total_before = BigDecimal("0")
        in_total_before = BigDecimal("0")
        item_out_before.each do |item|
            if item.item_type == "sell"
                parents = ItemRelationship.where(child_item_id: item.id)
                parents.each do |p|
                    out_total_before += BigDecimal(p.price.to_s) * BigDecimal(p.qty.to_s)
                end
            else
                out_total_before += BigDecimal(item.price.to_s) * BigDecimal(item.qty.to_s)
            end
        end
        item_in_before.each do |item|
            in_total_before += BigDecimal(item.price.to_s) * BigDecimal(item.qty.to_s)
        end
        inv_before = in_total_before - out_total_before
        item_in_after = Item.where(created_at: ..end_of_day).where(in_out: "in")
        item_out_after = Item.where(created_at: ..end_of_day).where(in_out: "out")

        out_total_after = BigDecimal("0")
        in_total_after = BigDecimal("0")
        item_out_after.each do |item|
            if item.item_type == "sell"
                parents = ItemRelationship.where(child_item_id: item.id)
                parents.each do |p|
                    out_total_after += BigDecimal(p.price.to_s) * BigDecimal(p.qty.to_s)
                end
            else
                out_total_after += BigDecimal(item.price.to_s) * BigDecimal(item.qty.to_s)
            end
        end
        item_in_after.each do |item|
            in_total_after += BigDecimal(item.price.to_s) * BigDecimal(item.qty.to_s)
        end
        inv_after = in_total_after - out_total_after
        sell_cogs = Item.where(created_at: start_of_day..end_of_day).where(item_type: "sell")
        cogs_sold = 0
        sell_cogs.each do |sell1|
            items = ItemRelationship.where(child_item_id: sell1.id)
            items.each do |i|
                cogs_sold += BigDecimal(i[:qty].to_s) * BigDecimal(i[:price].to_s)
            end
        end
        increase_inv = inv_after - inv_before
        a = Order.where(created_at: start_of_day..end_of_day).where(order_type: "to_receive").sum("total_amount")
        b = Order.where(created_at: start_of_day..end_of_day).where(order_type: "prepaid").sum("total_amount")
        c = Order.where(created_at: start_of_day..end_of_day).where(order_type: "tr_received").sum("total_amount")
        d = Order.where(created_at: start_of_day..end_of_day).where(order_type: "pp_received").sum("total_amount")
        increase_rec = a + b - c - d
        d = Order.where(created_at: start_of_day..end_of_day).where(order_type: "to_pay").sum("total_amount")
        e = Order.where(created_at: start_of_day..end_of_day).where(order_type: "prereceived", in_out: "not_applicable").sum("total_amount")
        f = Order.where(created_at: start_of_day..end_of_day).where(order_type: "tp_paid").sum("total_amount")
        g = Order.where(created_at: start_of_day..end_of_day).where(order_type: "pr_paid").sum("total_amount")
        increase_pay = d + e - f - g
        net_profit = BigDecimal(sell_total.to_s) - cogs_total - BigDecimal(expense_total.to_s)+ BigDecimal(income_total.to_s)
        sell_all_before = Order.where(created_at: ..start_of_day).where(order_type: "to_receive")
        sell_all_total_before = sell_all_before.sum("total_amount")
        sell_all_cogs_before = 0
        sell_all_before.each do |order_all|
            order_all.items.each do |item_all|
                item_all.parent_relationships.each do |p_all|
                    sell_all_cogs_before += BigDecimal(p_all[:price].to_s) * BigDecimal(p_all[:qty].to_s)
                end
            end
        end
        order_from = Order.where(created_at: ..start_of_day)
        equity_total_before = order_from.where(order_type: "cash_added").sum("total_amount")
                                - order_from.where(order_type: "cash_withdrawn").sum("total_amount")

        equity_total_after = Order.where(created_at: ..end_of_day).where(order_type: "cash_added").sum("total_amount")
                            - Order.where(created_at: ..end_of_day).where(order_type: "cash_withdrawn").sum("total_amount")
        increase_equity = equity_total_after - equity_total_before
        cal_cash_before =
            Order.where(created_at: ..start_of_day)
                .where.not(in_out: "cash_added")
                .where(in_out: "in")
                .sum(:total_amount) -
            Order.where(created_at: ..start_of_day)
                .where.not(in_out: "cash_withdrawn")
                .where(in_out: "out")
                .sum(:total_amount)

        orders = Order.where(created_at: ..start_of_day)

        cal_cash = sell_total - cogs_total + income_total - expense_total + BigDecimal(cal_cash_before) + BigDecimal(increase_equity) - increase_inv + BigDecimal(increase_pay) - BigDecimal(increase_rec)
        render json: {
            increase_equity: increase_equity,
            cal_cash: cal_cash,
            cal_cash_before: cal_cash_before,
            increase_pay: increase_pay,
            increase_rec: increase_rec,
            increase_inv: increase_inv,
            profit_before: net_profit_from,
            net_profit: net_profit,
            equity_total: equity_total,
            cash_total: cash_total,
            inv_total: inv_total,
            rec_total: rec_total,
            pay_total: pay_total,
            sell_total: sell_total,
            cogs_total: cogs_total,
            expense: expense,
            expense_total: expense_total,
            income: income,
            income_total: income_total,
            sells: sell_orders.as_json(
                include: {
                    items: {
                    include: :parents
                    }
                })
            }
    end
end
