class Spree::InvoiceLine < ActiveRecord::Base
  belongs_to :board_products
end