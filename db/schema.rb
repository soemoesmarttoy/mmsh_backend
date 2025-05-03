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

ActiveRecord::Schema[8.0].define(version: 2025_05_01_124609) do
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

  create_table "item_relationships", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "parent_item_id", null: false
    t.bigint "child_item_id", null: false
    t.index ["child_item_id"], name: "index_item_relationships_on_child_item_id"
    t.index ["parent_item_id"], name: "index_item_relationships_on_parent_item_id"
  end

  create_table "items", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.decimal "price", precision: 15, scale: 2
    t.decimal "qty", precision: 15, scale: 2
    t.decimal "last_total", precision: 15, scale: 2
    t.string "in_out"
    t.string "item_type"
    t.bigint "order_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_items_on_order_id"
    t.index ["product_id"], name: "index_items_on_product_id"
  end

  create_table "order_relationships", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "parent_order_id", null: false
    t.bigint "child_order_id", null: false
    t.index ["child_order_id"], name: "index_order_relationships_on_child_order_id"
    t.index ["parent_order_id"], name: "index_order_relationships_on_parent_order_id"
  end

  create_table "orders", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.string "order_type"
    t.bigint "customer_id"
    t.string "in_out"
    t.decimal "total_amount", precision: 15, scale: 2
    t.decimal "last_total", precision: 15, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_orders_on_customer_id"
  end

  create_table "products", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.string "name"
    t.bigint "pcode"
  end

  add_foreign_key "item_relationships", "items", column: "child_item_id"
  add_foreign_key "item_relationships", "items", column: "parent_item_id"
  add_foreign_key "items", "orders"
  add_foreign_key "items", "products"
  add_foreign_key "order_relationships", "orders", column: "child_order_id"
  add_foreign_key "order_relationships", "orders", column: "parent_order_id"
  add_foreign_key "orders", "customers"
end
