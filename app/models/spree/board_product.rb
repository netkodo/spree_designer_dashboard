class Spree::BoardProduct < ActiveRecord::Base

  belongs_to :option, :class_name => "Spree::PropertyConnectImage", :primary_key => "property_image_file_name"
  belongs_to :board
  belongs_to :product
  belongs_to :custom_item
  before_create :set_z_index

  has_attached_file :photo,
                    styles: {mini: '48x48>', small: '160x160>', product: '460x460>',large: '900x900>', thumb:'120x120>', xlarge: '1200x1200>', featured: '360x206>', listing:'260x260>'},
                    default_style: :product,
                    url: 'board_products/:id/:style/:basename.:extension',
                    path: 'board_products/:id/:style/:basename.:extension'


  default_scope  { where("#{Spree::BoardProduct.quoted_table_name}.deleted_at IS NULL") }
  
  state_machine :state, :initial => :pending_approval do
    event :mark_for_approval do
      transition [:pending_approval, :marked_for_deletion, :marked_for_removal] => :marked_for_approval
    end
    
    event :approve do
      transition [:pending_approval, :marked_for_deletion, :marked_for_approval] => :approved
    end
    
    event :remove do
      transition :marked_for_removal => :removed, :unless => :published_on_site
    end
    
    event :mark_for_removal do
      transition [:pending_approval, :marked_for_approval, :approved] => :marked_for_removal, :unless => :published_on_site
    end
    
    event :delete do
      transition [:pending_approval, :marked_for_approval, :approved] => :deleted, :unless => :published_on_site
    end
    
    event :mark_for_deletion do
      transition [:pending_approval, :marked_for_approval, :approved] => :marked_for_deletion, :unless => :published_on_site
    end
    
  end
  
  
  def published_on_site
    false
  end
  
  def self.by_supplier(supplier_id)
    includes(:product).where("products.supplier_id = #{supplier_id}").references(:product)
  end
  
  def set_z_index
    self.z_index = self.board.board_products.size
  end
  
  def destroy
    board = self.board
    self.update_attribute('deleted_at', Time.zone.now)
    if board
      board.board_products.reload
      board.queue_image_generation
    end
  end
  
  def self.marked_for_removal
    where(:state => "marked_for_removal")
  end
  
  def self.marked_for_deletion
    where(:state => "marked_for_deletion")
  end
  
  def self.marked_for_approval
    where(:state => "marked_for_approval")
  end
  
  def self.approved
    where(:state => "approved")
  end
  
  def self.pending_approval
    where(:state => "pending_approval")
    #includes(:product).where("isnull(spree_products.deleted_at) and isnull(spree_board_products.approved_at) and isnull(spree_board_products.removed_at)")
  end

  def self.calculate_subtotal(obj)
    customer_cost = BigDecimal(0)
    your_cost = BigDecimal(0)
    obj.each do |s|
      if s.product.present?
        if s.invoice_line.present? and s.invoice_line.price.present?
          customer_cost += s.invoice_line.price
          your_cost += s.invoice_line.price
        else
          customer_cost += s.product.price
          your_cost += s.product.cost_price
        end
      else
        if s.invoice_line.present? and s.invoice_line.price.present?
          customer_cost += s.invoice_line.price
          your_cost += s.invoice_line.price
        else
          customer_cost += s.custom_item.price
          your_cost += s.custom_item.price
        end
      end
    end
    [your_cost, customer_cost]
  end

end