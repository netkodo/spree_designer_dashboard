class Spree::Project < ActiveRecord::Base
  has_many :boards, dependent: :destroy
  has_many :project_histories, dependent: :destroy
  has_one :contract, dependent: :destroy
  belongs_to :user
  has_many :project_invoice_lines
  has_many :project_payments, dependent: :destroy

  validates :email, presence: true, if: :validate_only_update
  validates :project_name, presence: true, if: :validate_only_update
  validates :zip_code, presence: true, length: { minimum: 5 }

  scope :inclues_private_boards, -> { includes(:boards).where("spree_boards.private = true") }
  scope :close, -> {where(status: "close")}
  scope :open, -> {where(status: "open")}

  def validate_only_update
    !self.new_record?
  end

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
          'Monthly'
        when 'at_completion'
          'Bill At Project Completion'
        when 'bi_monthly'
          'Bi-Monthly'
        when 'quarterly'
          'Quarterly'
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
      when 'flat_rate_percentage'
        'flat rate / percentage of entire project'
      else
        'ERROR'
    end
  end

  def rate_title
    case self.rate_type
      when 'flat_rate_percentage'
        'Percentage Amount'
      else
        'Rate Amount'
    end
  end

  def show_percentage
    self.rate_type == 'flat_rate_percentage' ? '%' : ''
  end

  def show_dolar
    self.rate_type == 'flat_rate_percentage' ? '' : '$'
  end

  def display_rate
    self.rate_type == 'flat_rate_percentage' ? self.rate.to_i : self.rate
  end

  def flat_percentage?
    self.rate_type == 'flat_rate_percentage' ? true : false
  end

  def charge_on_statement
    case self.charge_on
      when "all_products"
        "On all merchandise purchases related to the Project (defined below)."
      when "alternate"
        "Only if Client purchases alternate merchandise not selected by the Designer for the Project (defined below)."
    end
  end

  def select_customer_billing_cycle
    tab = ['flat_rate_project','hourly_rate','flat_rate_percentage','flat_rate_room']
    flat = [['Customer Billing Cycle','placeholder',{disabled: 'disabled'}],['BILL AT START OF PROJECT','at_start'],['BILL AT PROJECT COMPLETION','at_completion']]
    hourly = [
        ['Customer Billing Cycle','placeholder',{disabled: 'disabled'}],
        ['WEEKLY','weekly'],
        ['BI-WEEKLY','bi_weekly'],
        ['MONTHLY','monthly'],
        ['BI-MONTHLY','bi_monthly'],
        ['QUARTERLY','quarterly'],
        ['AT PROJECT COMPLETION','at_completion'],
    ]
    tab.include?(self.rate_type) ? hourly : flat
  end

  def set_project_payment(history_id)
    if self.project_payments.exists? and self.project_payments.where(project_history_id: history_id).exists?
      payment = self.project_payments.where(project_history_id: history_id).first.update(payment_token: SecureRandom.uuid, project_history_id: history_id)
    else
      payment = self.project_payments.create(payment_token: SecureRandom.uuid, project_history_id: history_id )
    end
    payment.payment_token
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