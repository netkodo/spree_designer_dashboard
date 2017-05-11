class Spree::WallColor < ActiveRecord::Base

  belongs_to :board

  has_attached_file :wall_color,
                    styles: {normal: '160x160>'},
                    default_style: :normal,
                    url: 'wall_colors/:id/:style/:basename.:extension',
                    path: 'wall_colors/:id/:style/:basename.:extension'

end