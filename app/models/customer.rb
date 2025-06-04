class Customer < ApplicationRecord
    has_many :orders
    has_many :pre_sells
end
