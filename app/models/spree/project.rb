class Spree::Project < ActiveRecord::Base
  has_many :boards

  def get_customer_billing_cycle
    if self.rate_type == 'flat_rate'
      case self.customer_billing_cycle
        when 'at_start'
          'BILL AT START OF PROJECT'
        when 'at_completion'
          'BILL AT PROJECT COMPLETION'
        else
          'ERROR'
      end
    else
      case self.customer_billing_cycle
        when 'weekly'
          'WEEKLY'
        when 'bi_weekly'
          'BI-WEEKLY'
        when 'monthly'
          'MONTHLY'
        when 'at_completion'
          'BILL AT PROJECT COMPLETION'
        else
          'ERROR'
      end
    end
  end
end