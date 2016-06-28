class Spree::PortfolioFavorite < ActiveRecord::Base

  belongs_to :spree_user

  validates :user_id, :uniqueness => { :scope => :portfolio_id }

  def is_favorite?
    self
  end

end