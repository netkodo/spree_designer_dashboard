class Spree::Project < ActiveRecord::Base
  has_many :boards, dependent: :destroy
  has_many :project_histories, dependent: :destroy
  has_one :contract, dependent: :destroy

  def get_customer_billing_cycle
    if self.rate_type == 'flat_rate'
      case self.customer_billing_cycle
        when 'at_start'
          'Bill At Start Of Project'
        when 'at_completion'
          'Bill At Project Completion'
        else
          'ERROR'
      end
    else
      case self.customer_billing_cycle
        when 'weekly'
          'Weekly'
        when 'bi_weekly'
          'Bi-Weekly'
        when 'monthly'
          'Mmonthly'
        when 'at_completion'
          'Bill At Project Completion'
        else
          'ERROR'
      end
    end
  end
end