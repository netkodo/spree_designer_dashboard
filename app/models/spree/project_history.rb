class Spree::ProjectHistory < ActiveRecord::Base

  belongs_to :project
  has_many :project_invoice_lines
  has_one :project_payment

  has_attached_file :pdf,
                    :path => "pdf_invoices/:id/:basename.:extension"
  validates_attachment :pdf, :content_type => {:content_type => %w(application/pdf)}

  def self.manage_contract_state(project,action,pdf=nil)
    if project.project_histories.present?
      history = project.project_histories.where("action LIKE 'contract_%'").first
      if history.present?
        pdf.present? ? history.update(action: action,pdf: pdf) : history.update(action: action)
      else
        history = pdf.present? ?  Spree::ProjectHistory.create(action: action,pdf: pdf,project_id: project.id) : Spree::ProjectHistory.create(action: action,project_id: project.id)
      end
    else
      history = pdf.present? ? Spree::ProjectHistory.create(action: action,project_id: project.id,pdf: pdf) : Spree::ProjectHistory.create(action: action,project_id: project.id)
    end
    history
  end

  def add_date_base_on_billing_cycle
    case self.project.customer_billing_cycle
      when "weekly"
        1.week
      when "bi_weekly"
        2.weeks
      when "monthly"
        1.month
      when 'bi_monthly'
        2.months
      when 'quarterly'
        3.months
      else
        0
    end
  end

end
