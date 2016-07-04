class Spree::PortfolioFavorite < ActiveRecord::Base

  belongs_to :user
  belongs_to :portfolio

  validates :user_id, :uniqueness => { :scope => :portfolio_id }

end