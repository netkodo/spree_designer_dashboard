class Spree::Room < ActiveRecord::Base

  belongs_to :user
  has_many :portfolios

end
