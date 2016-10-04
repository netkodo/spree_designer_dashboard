class Spree::InvoiceLine < ActiveRecord::Base
  belongs_to :boards
  belongs_to :products
end
