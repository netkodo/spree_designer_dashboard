class Spree::Project < ActiveRecord::Base
  has_many :boards
  belongs_to :state
end