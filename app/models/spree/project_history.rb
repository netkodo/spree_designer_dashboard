class Spree::ProjectHistory < ActiveRecord::Base

  belongs_to :project

  has_attached_file :pdf,
                    :path => "pdf_invoices/:id/:basename.:extension"
  validates_attachment :pdf, :content_type => {:content_type => %w(application/pdf)}

end
