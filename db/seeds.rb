ActiveRecord::Base.transaction do
    # Create Customers
    cust_name = [ "main", "mg mg" ]
    cust_name.each do |c|
      customer = Customer.create!(name: c)
      puts "Created customer: #{customer.name}"
    end

    # Create Quality Categories
    q_names = [ "dried", "wet", "normal", "special", "color sorted", "single polished color sorted", "double polished color sorted" ]
    q_arr = q_names.map do |q|
      Category.create!(name: q, category_type: "quality")
    end

    # Create Main Categories
    c_names = [ "paddy", "rice", "medium rice" ]
    c_arr = c_names.map do |c|
      Category.create!(name: c, category_type: "main")
    end

    # Create Output Categories
    # Create Variation Categories
    v_names = [ "1", "30", "28.5", "29", "30.75", "30.7" ]
    v_arr = v_names.map do |v|
      Category.create!(name: v, category_type: "variation")
    end

    # Create Unit Categories
    u_names = [ "tin", "vs" ]
    u_arr = u_names.map do |u|
      Category.create!(name: u, category_type: "unit")
    end

    # Create Products for Paddy with wet/dried and variation "1" and unit "tin"
    p_names = [ "Byot New", "Byot Old", "Sin Thu Kha New", "Sin Thu Kha Old", "Nhan Ghaut New", "Nhan Ghaut Old" ]
    count1 = 1000
    count2 = 0
    old_count2 = count2
    count3 = 0
    p_names.each do |p|
        count2 += 100
      c_names.each do |c|
        next unless c == "paddy"

        q_names.each do |q|
          next unless [ "wet", "dried" ].include?(q)
          if count2 != old_count2
            old_count2 = count2
            count3 = 0
          end
          count3 += 10

          v_arr.each do |v|
            next unless v.name == "1"

            u_arr.each do |u|
              next unless u.name == "tin"

              Product.create!(
                name: p,
                categories: [
                  c_arr.find { |cat| cat.name == c },
                  q_arr.find { |cat| cat.name == q },
                  v,
                  u
                ],
                pcode: (count1 + count2 + count3) * 100
              )
              puts "Created product #{p} #{count1 + count2 + count3} for Paddy: #{q}, #{v.name}, #{u.name}"
            end
          end
        end
      end
    end

    # Create Products for non-Paddy with other qualities, variations, and units
    count1 = 1000
    oldCount1 = 1000
    count2 = 0
    oldCount2 = 0
    count3 = 0
    oldCount3 = 0
    count4 = 0
    c_names.each do |c|
      next if c == "paddy"
      count1 += 1000
      p_names.each do |p|
        if oldCount1 != count1
            count2 = 0
            oldCount1 = count1
        end
        count2 += 100
        q_names.each do |q|
          next if [ "wet", "dried" ].include?(q)
          if oldCount2 != count2
            count3 = 0
            oldCount2 = count2
          end
          count3 += 10
          v_arr.each do |v|
            next if v.name == "1"
            u_arr.each do |u|
              next if u.name == "tin"
            if oldCount3 != count3
                count4 = 0
                oldCount3 = count3
            end
            count4 += 1
              Product.create!(
                name: p,
                categories: [
                  c_arr.find { |cat| cat.name == c },
                  q_arr.find { |cat| cat.name == q },
                  v,
                  u
                ],
                pcode: (count1 + count2 + count3 + count4) * 100
              )
              puts "Created product #{p} with #{count1+count2+count3+count4} for #{c}: #{q}, #{v.name}, #{u.name}"
            end
          end
        end
      end
    end
    other_cat = Category.create!(name: "other", category_type: "main")
    twenty_cat = Category.create!(name: "20", category_type: "variation")
    Product.create!(
      name: "Small Rice",
      categories: [
        other_cat,
        q_arr.find { |cat| cat.name == "normal" },
        v_arr.find { |v| v.name === "30" },
        u_arr.find { |u| u.name == "vs" }
      ],
      pcode: 4001 * 100
    )
    Product.create!(
      name: "Small Rice",
      categories: [
        other_cat,
        q_arr.find { |cat| cat.name == "color sorted" },
        v_arr.find { |v| v.name === "30" },
        u_arr.find { |u| u.name == "vs" }
      ],
      pcode: 4002 * 100
    )
    Product.create!(
      name: "Phwal Nu",
      categories: [
        other_cat,
        q_arr.find { |cat| cat.name == "normal" },
        twenty_cat,
        u_arr.find { |u| u.name == "vs" }
      ],
      pcode: 5001 * 100
    )
    Product.create!(
      name: "Phwal Nu",
      categories: [
        other_cat,
        q_arr.find { |cat| cat.name == "color sorted" },
        twenty_cat,
        u_arr.find { |u| u.name == "vs" }
      ],
      pcode: 5002 * 100
    )
    Product.create!(
      name: "Point",
      categories: [
        other_cat,
        q_arr.find { |cat| cat.name == "normal" },
        twenty_cat,
        u_arr.find { |u| u.name == "vs" }
      ],
      pcode: 6001 * 100
    )
    Product.create!(
      name: "Point",
      categories: [
        other_cat,
        q_arr.find { |cat| cat.name == "color sorted" },
        twenty_cat,
        u_arr.find { |u| u.name == "vs" }
      ],
      pcode: 6002 * 100
    )
    rejected_q = Category.create!(name: "reject", category_type: "quality")
    Product.create!(
      name: "Reject Rice",
      categories: [
        c_arr.find { |c| c.name == "rice" },
        rejected_q,
        v_arr.find { |v| v.name === "30" },
        u_arr.find { |u| u.name == "vs" }
      ],
      pcode: 7001 * 100
    )
    Product.create!(
      name: "Reject Medium Rice",
      categories: [
        c_arr.find { |c| c.name == "medium rice" },
        rejected_q,
        v_arr.find { |v| v.name === "30" },
        u_arr.find { |u| u.name == "vs" }
      ],
      pcode: 8001 * 100
    )
    incomes = [ "general", "rent_dried", "rent_produced" ]
    incomes.each do |i|
        IncomeCategory.create!(
            name: i
        )
    end
    expenses = [ "general", "direct_labour_cost", "transportation", "electricity", "fuel", "tax", "rent_for_buildings", "rent_for_machines", "give_rent", "salary" ]
    expenses.each do |e|
        ExpenseCategory.create!(
            name: e
        )
    end
    users = [ "admin", "user", "buyer", "seller", "producer", "cashier", "main" ]
    users.each do |user|
      User.create!(
        username: user,
        email: user + '@gmail.com',
        password: user,
        role: user
      )
      Customer.create!(
        name: user
      )
    end
  end
