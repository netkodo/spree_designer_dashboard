class Spree::DesignerRegistrationsController < Spree::StoreController
  before_action :set_designer_registration, only: [:show, :edit, :update, :destroy]
  layout "/spree/layouts/splash"
  before_filter :check_existing_registration, :only => [:new]
  
  # GET /designer_registrations
  def index

  end

  # GET /designer_registrations/1
  def show
  end

  # GET /designer_registrations/new
  def new
  #   @user = Spree::User.new
  #   @designer_registration = Spree::DesignerRegistration.new
  #   @designer_registration.user = @user
  end

  def designer_signup
    @user = Spree::User.new
    @designer_registration = Spree::DesignerRegistration.new
    @designer_registration.user = @user
  end

  # GET /designer_registrations/1/edit
  def edit
  end

  # POST /designer_registrations
  def create
    @designer_registration = current_spree_user.designer_registrations.new(designer_registration_params)
    @designer_registration.status = 'pending'

    @designer_registration.user.first_name=params[:designer_registration][:first_name]
    @designer_registration.user.last_name=params[:designer_registration][:last_name]
    if @designer_registration.user.save
      Rails.logger.info "FIRST/LAST NAME SET"
    end

    if @designer_registration.save
      redirect_to designer_registration_thanks_path
    else
      render action: 'new'
    end
  end
  
  def thanks
    
  end

  # PATCH/PUT /designer_registrations/1
  def update
    if @designer_registration.update(designer_registration_params)
      redirect_to @designer_registration, notice: 'Designer registration was successfully updated.'
    else
      render action: 'edit'
    end
  end

  # DELETE /designer_registrations/1
  def destroy
    @designer_registration.destroy
    redirect_to designer_registrations_url, notice: 'Designer registration was successfully destroyed.'
  end

  def all_access_designer

  end

  private
  
    def check_existing_registration
      if spree_current_user and !spree_current_user.designer_registrations.blank?
        redirect_to "/"
      end
    end
    
    # Use callbacks to share common setup or constraints between actions.
    def set_designer_registration
      @designer_registration = Spree::DesignerRegistration.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def designer_registration_params
      params.require(:designer_registration).permit(:first_name,:last_name,:company_name, :address1, :address2, :city, :state, :postal_code, :phone, :website, :resale_certificate_number, :tin, :user_id,:applied_for)
    end
    
end
