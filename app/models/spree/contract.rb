class Spree::Contract < ActiveRecord::Base

  belongs_to :project

  has_attached_file :designer_sign,
                    styles: {},
                    default_style: :original,
                    path: 'signatures/designer_sign/:id/:style/:basename.:extension',
                    convert_options: { all: '-strip -auto-orient -colorspace sRGB' }

  has_attached_file :client_sign,
                    styles: {},
                    default_style: :original,
                    path: 'signatures/client_sign/:id/:style/:basename.:extension',
                    convert_options: { all: '-strip -auto-orient -colorspace sRGB' }

end