class Spree::DesignerRegistration < ActiveRecord::Base
  require 'mandrill'
  #attr_accessible :address1, :address2, :city, :state, :postal_code, :phone, :website, :resale_certificate_number, :tin, :company_name, :status, :first_name, :last_name
  belongs_to :user, :class_name => "User"

  validates_presence_of :address1, :city, :state, :postal_code, :phone, :website, :tin, :company_name
  #validates_presence_of :first_name, :last_name

  after_create :send_designer_welcome
  after_create :update_profile_information
  after_create :send_no_activity_email
  after_update :update_designer_status

  def update_profile_information
    if self.user
      user = self.user
      user.build_username
      user.update_attributes({:location => "#{self.city}, #{self.state}",
                              :website_url => self.website,
                              :company_name => self.company_name})
    end
  end

  def self.status_options
    [["Pending Review", "pending"], ["Room Designer", "room designer"], ["To the Trade Designer", "to the trade designer"], ["Declined", "declined"]]
  end

  def update_designer_status

    Rails.logger.info "##########################"
    Rails.logger.info "##########################"
    Rails.logger.info "##########################"
    user = self.user
    Rails.logger.info "User: #{user.email}"
    if self.status_changed?
      case self.status
        when "pending"
          user.update_attributes({:is_discount_eligible => 0, :can_add_boards => 0})
        when "room designer"
          boards = user.boards.where(status: "published").count
          if boards > 0 and user.user_images.count == 1
            user.update_attributes({:is_discount_eligible => 1, :can_add_boards => 1, :show_designer_profile => 1})
          else
            user.update_attributes({:is_discount_eligible => 1, :can_add_boards => 1})
          end
          self.send_email_to_designer("","Congratulations! Your application has been accepted!","Jesse Bodine","","approved-room-design-new-email")
          user.add_designer_to_mailchimp
        when "to the trade designer"
          user.update_attributes({:is_discount_eligible => 1, :can_add_boards => 0})
          self.send_email_to_designer("","Congratulations! You have been accepted into the Scout & Nimble Trade Designer Program!","Jesse Bodine","","approved-trade-designer")
          user.add_designer_to_mailchimp
        when "declined"
          user.update_attributes({:is_discount_eligible => 0, :can_add_boards => 0})
          self.send_email_to_designer("","Your application has been declined!","Jesse Bodine","","we-have-our-eye-on-you")
      end
    end
  end

  def update_old_designer_status
    @designers = Spree::DesignerRegistration.all

    @designers.each do |design|
      puts design.status
      if design.status == "accepted-designer"
        design.update_column(:status, "room designer")
      end
      if design.status == "accepted-affiliate"
        design.update_column(:status, "to the trade designer")
      end
      # if design.status == "new"
      #   design.update_column(:status,"pending")
      # end
    end

  end

  def send_no_activity_email
    Resque.enqueue_at(7.days.from_now, NoActivityEmailsToDesigners, self.id)
  end

  def send_designer_welcome
    html_content = ''
    logger.info "Sending the mail to #{self.user.email}"

    m = Mandrill::API.new(MANDRILL_KEY)
    message = {
        :subject => "Thank you for submitting your application!",
        :from_name => "Jesse Bodine",
        :text => "Thanks for registering to be a Scout & Nimble room designer.  Please stay tuned as we'll be in touch soon!  \n\n The Scout & Nimble Team",
        :to => [
            {
                :email => self.user.email,
                :name => self.user.full_name
            }
        ],
        :from_email => "designer@scoutandnimble.com",
        :track_opens => true,
        :track_clicks => true,
        :url_strip_qs => false,
        :signing_domain => "scoutandnimble.com"
    }

    message_for_self = {
        :subject => "New user has applied: #{self.user.first_name} #{self.user.last_name}",
        :from_name => "Jesse Bodine",
        :text => "New user has applied: #{self.user.first_name} #{self.user.last_name} \n\n The Scout & Nimble Team",
        :to => [
            {
                :email => "designer@scoutandnimble.com",
                :name => "Scout & Nimble"
            }
        ],
        :from_email => "designer@scoutandnimble.com",
        :track_opens => true,
        :track_clicks => true,
        :url_strip_qs => false,
        :signing_domain => "scoutandnimble.com",

        :merge_vars => [
            {
                :rcpt => self.user.email,
                :vars => [
                    {
                        :name => "firstname",
                        :content => self.user.first_name
                    },
                    {
                        :name => "lastname",
                        :content => self.user.last_name
                    }
                ]
            }
        ]
    }

    sending = m.messages.send_template('thank-you-for-applying', [{:name => 'main', :content => html_content}], message, true)
    sending_self = m.messages.send_template('new-designer-registration-self-info', [{:name => 'main', :content => html_content}], message_for_self, true)
    logger.info sending_self
    logger.info sending


  end

  def send_email_to_designer(html_content,subject,from_name,text,template)
    html_content = html_content
    logger.info "Sending the mail to #{self.user.email}"

    m = Mandrill::API.new(MANDRILL_KEY)
    message = {
        :subject => subject,
        :from_name => from_name,
        :text => text,
        :to => [
            {
                :email => self.user.email,
                :name => self.user.full_name
            }
        ],
        :from_email => "designer@scoutandnimble.com",
        :track_opens => true,
        :track_clicks => true,
        :url_strip_qs => false,
        :signing_domain => "scoutandnimble.com"
    }

    sending = m.messages.send_template(template, [{:name => 'main', :content => html_content}], message, true)

    logger.info sending
  end

end
