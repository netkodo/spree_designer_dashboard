class Spree::Project < ActiveRecord::Base
  has_many :boards, dependent: :destroy
  has_many :project_histories, dependent: :destroy
  has_one :contract, dependent: :destroy
  belongs_to :user
  has_many :project_invoice_lines

  scope :inclues_private_boards, -> { includes(:boards).where("spree_boards.private = true") }

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

  def display_rate_type
    case self.rate_type
      when 'flat_rate_room'
        'flat rate / per room'
      when 'flat_rate_project'
        'flat rate / entire project'
      when 'hourly_rate'
        'hourly rate'
      else
        'ERROR'
    end
  end

  def charge_on_statement
    case self.charge_on
      when "all_products"
        "on all products purchased related to merchandise ordering, whether or not they are included in the Project."
      when "alternate"
        "if Client buys alternate merchandise not presented by the Designer for the Project."
    end
  end

  def send_contract(from_addr,to_addr,to_name,pdf)
    html_content = ''
    m = Mandrill::API.new(MANDRILL_KEY)

    message = {
        :subject => "CONTARCT",
        :from_name => "INVOICE",
        :text => "INVOICE",
        :to => [
            {
                :email => to_addr,
                :name => to_name
            }
        ],
        :from_email => from_addr,
        :track_opens => true,
        :track_clicks => true,
        :url_strip_qs => false,
        :signing_domain => "scoutandnimble.com",
        :merge_language => "handlebars",
        :attachments => [
            {
                :type => "pdf",
                :name => "contract.pdf",
                :content => Base64.encode64(pdf)
            }
        ]
    }
    sending = m.messages.send_template('invoice-email', [{:name => 'main', :content => html_content}], message, true)
  end

end