class Spree::InvoiceLine < ActiveRecord::Base
  belongs_to :boards
  belongs_to :products
  belongs_to :custom_items
end
