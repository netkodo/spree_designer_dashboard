class Spree::Portfolio < ActiveRecord::Base

  belongs_to :user
  belongs_to :board
  belongs_to :color
  belongs_to :room_types, foreign_key: 'room_type', class_name: "Spree::Taxon"
  belongs_to :room_styles, foreign_key: 'style', class_name: "Spree::Taxon"
  has_many :portfolio_favorites, dependent: :destroy
  validates :name, presence: true

  has_attached_file :portfolio_image,
                    styles: { small: '90x90>', medium: '180x180>', large: '600x600>' },
                    default_style: :medium,
                    path: 'portfolio_images/:id/:style/:basename.:extension',
                    convert_options: { all: '-strip -auto-orient -colorspace sRGB' }

  validates_attachment_presence :portfolio_image

  def change_name_to_class
      self.name.gsub(' ','_')
  end

  def change_class_to_name
    self.name.gsub('_',' ')
  end

  def is_favorite?(user)
    self.portfolio_favorites.find_by(user_id: user.id) ? true : false
  end

  def self.portfolios_ordering(obj)
    z = {}
    obj.each_with_index do |t,i|
      if i%4 == 0
        i<4 ? z[0] = [t] : z[0] << t
      elsif i%4 == 1
        i<4 ? z[1] = [t] : z[1] << t
      elsif i%4 == 2
        i<4 ? z[2] = [t] : z[2] << t
      else i%4 == 3
      i<4 ? z[3] = [t] : z[3] << t
      end
    end
    z
  end

end
