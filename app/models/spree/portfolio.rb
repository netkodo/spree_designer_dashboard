class Spree::Portfolio < ActiveRecord::Base

  belongs_to :spree_user
  validates :name, presence: true

  has_attached_file :portfolio_image,
                    styles: { small: '90x90>', medium: '180x180>', large: '600x600>' },
                    default_style: :medium,
                    path: 'portfolio_images/:id/:style/:basename.:extension',
                    convert_options: { all: '-strip -auto-orient -colorspace sRGB' }

  validates_attachment_presence :portfolio_image
end