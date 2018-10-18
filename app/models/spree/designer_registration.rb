class Spree::DesignerRegistration < ActiveRecord::Base
  #attr_accessible :address1, :address2, :city, :state, :postal_code, :phone, :website, :resale_certificate_number, :tin, :company_name, :status, :first_name, :last_name
  belongs_to :user, :class_name => "User"

  attr_accessor :validate_tin

  validates_presence_of :address1, :city, :state, :postal_code, :phone, :website, :company_name #, :tin
  validates :tin, presence: true, :if => :validate_tin?
  #validates_presence_of :first_name, :last_name

  after_create :create_cordial_profile
  after_create :update_profile_information
  after_update :update_designer_status
  after_update :update_approved_at

  def self.initialize_approved_at_date
    Spree::DesignerRegistration.all.find_each{|x| x.update_column(:approved_at, x.updated_at)}
  end

  def validate_tin?
    validate_tin
  end

  def update_approved_at
    if self.status_changed?
      self.update_column(:approved_at, DateTime.now)
    else
      puts "status not changed"
    end
  end

  def update_profile_information
    if self.user
      user = self.user
      user.build_username
      user.update_attributes({:location => "#{self.city}, #{self.state}",
                              :website_url => self.website,
                              :company_name => self.company_name})
    end
  end

  def validate_tin?
    validate_tin
  end

  def self.status_options
    [["Pending Review", "pending"], ["Room Designer", "room designer"], ["To the Trade Designer", "to the trade designer"], ["Test Designer", "test designer"], ["Declined", "declined"], ['All Access Only','all access'],['Room Designer w/ All Access','room all access']]
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
          Resque.enqueue CordialSignUpWorker, user.id
        when "room designer"
          # boards = user.boards.where(status: "published").count
          if user.user_images.count == 1#boards > 0 and
            user.update_attributes({:is_discount_eligible => 1, :can_add_boards => 1, :show_designer_profile => 1})
          else
            user.update_attributes({:is_discount_eligible => 1, :can_add_boards => 1})
          end
          # Resque.enqueue_at(7.days.from_now, NoActivityEmailsToDesigners, self.id)
          # user.add_designer_to_mailchimp
          # user.designer_ac_registration("room designer")
          # user.user_ac_event_add("room_designer_accepted_event")
          Spree::DesignerRegistrationMailer.send_notification(user.id, "morganw@scoutandnimble.com", "Room Designer Approved", false).deliver
          user.designer_cordial_registration('Room-Designer-Accepted')
        when "to the trade designer"
          user.update_attributes({:is_discount_eligible => 1, :can_add_boards => 0})
          # user.add_designer_to_mailchimp
          # user.designer_ac_registration("to the trade designer")
          # user.user_ac_event_add("trade_designer_accepted_event")
          Spree::DesignerRegistrationMailer.send_notification(user.id, "morganw@scoutandnimble.com", "Trade Designer Approved", false).deliver
          user.designer_cordial_registration('Trade-Designer-Accepted')
        when "test designer"
          Resque.enqueue CordialSignUpWorker, user.id
          # boards = user.boards.where(status: "published").count
          if user.user_images.count == 1#boards > 0 and
            user.update_attributes({:is_discount_eligible => 1, :can_add_boards => 1, :show_designer_profile => 0})
          else
            user.update_attributes({:is_discount_eligible => 1, :can_add_boards => 1})
          end

          # user.designer_ac_registration("room designer")
        when "all access"
          user.update_attributes({:is_discount_eligible => 1, :can_add_boards => 1})
        when "room all access"
          user.update_attributes({:is_discount_eligible => 1, :can_add_boards => 1})
        when "declined"
          Resque.enqueue CordialSignUpWorker, user.id
          user.update_attributes({:is_discount_eligible => 0, :can_add_boards => 0})
          Spree::DesignerRegistrationMailer.decline_designer(user.email).deliver
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

  protected

    def create_cordial_profile
      user.designer_cordial_registration('Pending-Designer-Application')
    end

end
