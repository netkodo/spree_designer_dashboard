class Spree::Board < ActiveRecord::Base

  validates_presence_of :name
  
  has_many :board_products
  has_many :products, :through => :board_products
	belongs_to :designer, :class_name => "User", :foreign_key => "designer_id"
	has_many :color_matches
	has_many :colors, :through => :color_matches
	has_many :messages
	
	belongs_to :room, :foreign_key => "room_id", :class_name => "Spree::Taxon"
	belongs_to :style, :foreign_key => "style_id", :class_name => "Spree::Taxon"
	
	attr_accessible :name, :description, :style_id, :room_id, :status, :message, :featured
	
	has_one :board_image, as: :viewable, order: :position, dependent: :destroy, class_name: "Spree::BoardImage"
  attr_accessible :board_image_attributes, :messages_attributes
  accepts_nested_attributes_for :board_image, :messages
  is_impressionable
  
  def self.active
    where(:status => 'published')
  end
  
  def self.featured
    where(:featured => 1)
  end
  
  def room_and_style
    rs = []
    rs << self.room.name if self.room
    rs << self.style.name if self.style
    rs.join(", ")
  end
  
  def display_status
    case self.status
      
      when "new"
        "Draft - Not Published"
      when "submitted_for_publication"
        "Pending - Submitted for Publication"
      when "published"
        "Published"
      when "suspended"
        "Suspended"
      when "deleted"
        "Deleted"
      when "unpublished"
        "Unpublished"
      when "retired"
        "Retired"  
      when "needs_revision"
        "Pending - Revisions Requested"
      else
        "status not available"
    end
      
  end
  
  def self.by_style(style_id)
    where(:style_id => style_id)
  end
  
  def self.by_room(room_id)
    where(:room_id => room_id)
  end
  
  def self.by_color_family(color_family)
    related_colors = Spree::Color.by_color_family(color_family)
    
    includes(:colors).where('spree_colors.id' => related_colors.collect{|color| color.id})
  end
  
  def self.status_options
    [["Draft - Not Published", "new"], ["Pending - Submitted for Publication","submitted_for_publication"], ["Published","published"], ["Suspended","suspended"], ["Deleted","deleted"], ["Unpublished","unpublished"], ["Retired","retired"], ["Pending - Revisions Requested","needs_revision"]]
  end
  
  def self.color_categories
    ["Blue", "Cool Neutral", "Green", "Orange", "Red", "Violet", "Warm Neutral", "White", "Yellow"]
  end
  
  scope :by_color, (lambda do |color|
    joins(:color_matches).where('spree_color_matches.color_id = ?', color.id) unless color.nil?
  end)
  
  def self.by_designer(designer_id)
    where(:designer_id => designer_id)
  end
  
  def self.by_lower_bound_price(price)
    includes(:products).where('spree_products.id' => Spree::Product.master_price_gte(price).collect{|color| color.id})
    #includes(:products).where('spree_products.master_price > ?', price)
    #joins(:products).merge(Spree::Product.master_price_gte(price))
  end
  
  def self.by_upper_bound_price(price)
    includes(:products).where('spree_products.id' => Spree::Product.master_price_lte(price).collect{|color| color.id})
    #includes(:products).where('spree_products.master_price < ?', price)
    #joins(:products).merge(Spree::Product.master_price_lte(price))
  end
  
  
  
  #def render_board
  #  white_canvas = Image.new(720,400){ self.background_color = "white" }
  #  self.board_products.reload
  #  self.board_products.each do |bp|
  #  	product_image = ImageList.new(bp.product.images.first.attachment.url(:product))
  #  	product_image.scale!(bp.width, bp.height)
  #  	white_canvas.composite!(product_image, NorthWestGravity, bp.top_left_x, bp.top_left_y, Magick::OverCompositeOp)
  #  end
  #  white_canvas.format = 'jpeg'
  #  white_canvas.write("#{Rails.root}/boards/#{b.id}.jpg")
  #end
end