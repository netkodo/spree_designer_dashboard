Spree::User.class_eval do
  has_many :boards, foreign_key: :designer_id, order: "created_at desc"
  has_many :products, :through => :boards
  has_many :bookmarks
  has_many :rooms, dependent: :destroy
  has_many :designer_registrations
  has_many :portfolios, dependent: :destroy
  has_many :portfolio_favorites, dependent: :destroy
  has_many :board_favorites, dependent: :destroy
  #has_many :user_images, as: :viewable, dependent: :destroy, class_name: "Spree::UserImage"
  has_many :user_images, -> { order(:position) }, as: :viewable, dependent: :destroy, class_name: "Spree::UserImage"
  has_many :marketing_images, as: :viewable, dependent: :destroy, class_name: "Spree::MarketingImage"
  has_one :logo_image, as: :viewable, dependent: :destroy, class_name: "Spree::LogoImage"
  has_one :feature_image, as: :viewable, dependent: :destroy, class_name: "Spree::FeatureImage"
  accepts_nested_attributes_for :user_images, :logo_image, :marketing_images, :feature_image
  has_many :projects, dependent: :destroy
  is_impressionable
  
  def self.designers
    where("can_add_boards = 1 or is_discount_eligible = 1")
  end
  
  def self.published_designers
    where(:show_designer_profile => 1)
  end
  
  def is_designer?
    self.is_discount_eligible || self.can_add_boards
  end

  def designer_type
    d = self.designer_registrations.first
    status = d.present? ? d.status : 'Subscriber'
    status == 'room all access' ? 'Room designer with All-access' : status
  end

  def is_affiliate?
    self.is_discount_eligible
  end
  
  def is_board_designer?
    self.can_add_boards
  end
  
  def self.is_active_designer
    where(:can_add_boards => 1)
  end

  def check_designer_type(except)
    self.present? and self.designer_registrations.exists? and !except.include?(self.designer_registrations.first.status)
  end
  
end
