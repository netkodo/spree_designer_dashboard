class Spree::BoardFavorite < ActiveRecord::Base

  belongs_to :user
  belongs_to :board

  validates :user_id, :uniqueness => { :scope => :portfolio_id }

end