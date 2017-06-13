class Spree::Portfolio < ActiveRecord::Base

  belongs_to :user
  belongs_to :board
  belongs_to :color
  belongs_to :room_types, foreign_key: 'room_type', class_name: "Spree::Taxon"
  belongs_to :room_styles, foreign_key: 'style', class_name: "Spree::Taxon"
  has_many :portfolio_favorites, dependent: :destroy
  belongs_to :room

  has_many :portfolio_variant_associations, dependent: :destroy
  has_many :variants, through: :portfolio_variant_associations

  is_impressionable

  scope :visible, -> { where(show: true) }

  before_destroy :check_rooms

  validates :name, presence: true

  has_attached_file :portfolio_image,
                    styles: { small: '90x90>',carousel: '200x200>', medium: '400x300#', large: '600x600>' },
                    default_style: :medium,
                    path: 'portfolio_images/:id/:style/:basename.:extension',
                    convert_options: { all: '-strip -auto-orient -colorspace sRGB -quality 80' }

  validates_attachment_presence :portfolio_image, only: [:create_portfolio]

  def check_rooms
    # destroying room if removed portfolio was last in that rooom
    room = self.room
    if room.portfolios.count <= 1
      room.destroy
    end
  end

  def check_tags(check)
    tags = self.tags.split(',')
    tab = []
    check.each do |check|
      tags.include?(check) ? tab << true : tab << false
    end
    tab.include?(false) ? false : true
  end

  def self.create_rooms_for_existing_portfolios
    Spree::Portfolio.all.each do |p|
      unless p.room_id.present?
        r = Spree::Room.create(user_id: p.user_id)
        p.update(room_id: r.id)
      end
    end
  end

  def change_name_to_class
      self.name.gsub(' ','_')
  end

  def change_class_to_name
    self.name.gsub('_',' ')
  end

  def is_favorite?(user)
    self.portfolio_favorites.find_by(user_id: user.id) ? true : false
  end

  def self.portfolios_ordering(obj,cols)
    z = {}
    obj.each_with_index do |t,i|
      if i%cols == 0
        i<cols ? z[0] = [t] : z[0] << t
      elsif i%cols == 1
        i<cols ? z[1] = [t] : z[1] << t
      elsif i%cols == 2
        i<cols ? z[2] = [t] : z[2] << t
      else i%4 == 3
        i<4 ? z[3] = [t] : z[3] << t
      end
    end
    z
  end

  def self.get_filter_tags(obj)
    tab = []
    tmp=obj.map{|p| p.tags.split(',')}
    tmp.each do |tags|
      tags.each do |tag|
        tab << [tag,tag]
      end
    end
    tab
  end

end
