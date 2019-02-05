module Spree
  class SliderImage < ActiveRecord::Base
    validates_attachment :attachment, content_type: { content_type: %w(image/jpg image/jpeg image/png image/gif)}
    belongs_to :slide

    has_attached_file :attachment,
                      styles: { mini: '114x50>', small: '182x80>', primary: '342x150>', large: '684x300>', banner: '1140x500>' },
                      default_style: :primary,
                      url: '/spree/slider_images/:id/:style/:basename.:extension',
                      path: 'slider_images/:id/:style/:basename.:extension',
                      convert_options: { all: '-strip -auto-orient -quality 80' }

  end
end