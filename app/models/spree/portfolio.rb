class Spree::Portfolio < ActiveRecord::Base

  belongs_to :spree_user
  validates :name, presence: true


  # validates_attachment :portfolio_image, :presence => true ,:content_type => { content_type: ["image/jpg", "image/jpeg", "image/png", "image/gif"]}

  has_attached_file :portfolio_image,
                    styles: { small: '90x90>', medium: '180x180>', large: '600x600>' },
                    default_style: :medium,
                    path: 'portfolio_images/:id/:style/:basename.:extension',
                    convert_options: { all: '-strip -auto-orient -colorspace sRGB' }

  validates_attachment_presence :portfolio_image
  # validates_attachment_size :portfolio_image, :in => 1.kilobytes..2.megabytes
  validates_attachment_content_type :portfolio_image, :content_type => /\Aimage\/.*\Z/
end