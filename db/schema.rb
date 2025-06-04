# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_05_27_062643) do
  create_table "categories", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.string "name"
    t.string "category_type"
  end

  create_table "categories_products", id: false, charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "category_id", null: false
    t.bigint "product_id", null: false
    t.index ["category_id"], name: "index_categories_products_on_category_id"
    t.index ["product_id"], name: "index_categories_products_on_product_id"
  end

  create_table "customers", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.string "name"
  end

  create_table "expense_categories", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "expense_categories_orders", id: false, charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "expense_category_id", null: false
    t.index ["expense_category_id", "order_id"], name: "idx_on_expense_category_id_order_id_684197d5e0"
    t.index ["order_id", "expense_category_id"], name: "idx_on_order_id_expense_category_id_7da4263370"
  end

  create_table "income_categories", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "income_categories_orders", id: false, charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "income_category_id", null: false
    t.index ["income_category_id", "order_id"], name: "idx_on_income_category_id_order_id_809bc7623e"
    t.index ["order_id", "income_category_id"], name: "idx_on_order_id_income_category_id_7a14108cce"
  end

  create_table "item_relationships", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "parent_item_id", null: false
    t.bigint "child_item_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "qty", precision: 25, scale: 10
    t.decimal "price", precision: 25, scale: 10
    t.index ["child_item_id"], name: "index_item_relationships_on_child_item_id"
    t.index ["parent_item_id"], name: "index_item_relationships_on_parent_item_id"
  end

  create_table "items", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.decimal "price", precision: 25, scale: 10
    t.decimal "qty", precision: 25, scale: 10
    t.string "in_out"
    t.string "item_type"
    t.bigint "order_id"
    t.decimal "last_qty", precision: 25, scale: 10
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_items_on_order_id"
    t.index ["product_id"], name: "index_items_on_product_id"
  end

  create_table "order_relationships", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "parent_order_id", null: false
    t.bigint "child_order_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["child_order_id"], name: "index_order_relationships_on_child_order_id"
    t.index ["parent_order_id"], name: "index_order_relationships_on_parent_order_id"
  end

  create_table "orders", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.string "order_type"
    t.bigint "customer_id"
    t.string "in_out"
    t.decimal "total_amount", precision: 25, scale: 10
    t.decimal "last_total", precision: 25, scale: 10
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_orders_on_customer_id"
  end

  create_table "pre_produces", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "customer_id"
    t.bigint "product_id", null: false
    t.string "pre_produce_type"
    t.string "pre_produce_status"
    t.decimal "qty", precision: 25, scale: 10
    t.bigint "temp_id"
    t.string "in_out"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_pre_produces_on_customer_id"
    t.index ["product_id"], name: "index_pre_produces_on_product_id"
  end

  create_table "pre_sells", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "customer_id"
    t.decimal "total_amount", precision: 25, scale: 10
    t.decimal "qty", precision: 25, scale: 10
    t.decimal "price", precision: 25, scale: 10
    t.bigint "product_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_pre_sells_on_customer_id"
    t.index ["product_id"], name: "index_pre_sells_on_product_id"
  end

  create_table "products", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.string "name"
    t.bigint "pcode"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.string "username"
    t.string "email"
    t.string "password"
    t.string "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "item_relationships", "items", column: "child_item_id"
  add_foreign_key "item_relationships", "items", column: "parent_item_id"
  add_foreign_key "items", "orders"
  add_foreign_key "items", "products"
  add_foreign_key "order_relationships", "orders", column: "child_order_id"
  add_foreign_key "order_relationships", "orders", column: "parent_order_id"
  add_foreign_key "orders", "customers"
  add_foreign_key "pre_produces", "customers"
  add_foreign_key "pre_produces", "products"
  add_foreign_key "pre_sells", "customers"
  add_foreign_key "pre_sells", "products"
end
