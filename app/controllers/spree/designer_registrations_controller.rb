class Spree::DesignerRegistrationsController < Spree::StoreController
  before_action :set_designer_registration, only: [:show, :edit, :update, :destroy]
  # layout "/spree/layouts/splash"
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

    @designer_registration.user.first_name=params[:designer_registration][:first_name].strip
    @designer_registration.user.last_name=params[:designer_registration][:last_name].strip
    if @designer_registration.user.save
      Rails.logger.info "FIRST/LAST NAME SET"
    end

    @designer_registration.validate_tin = @designer_registration.applied_for == "room designer" ? true : false

    if @designer_registration.save
      session[:fb_pixel_email] = current_spree_user.email
      # @designer_registration.user.designer_ac_signup(@designer_registration.applied_for)
      if @designer_registration.applied_for == 'all access' and !@designer_registration.access_paid
        cookies[:designer_finish_form] = true
        # redirect_to '/designers/all-access-designer'
        respond_with @designer_registration, location: '/designers/all-access-designer'
      else
        Spree::DesignerRegistrationMailer.send_notification(@designer_registration.user_id).deliver
        redirect_to designer_registration_thanks_url
      end
    else
      cookies[:designer_registration] = params[:designer_registration][:applied_for]
      if params[:designer_registration][:applied_for] == "all access"
        render action: 'all_access_designer'
      else
        render action: 'designer_signup'
      end
    end
  end
  
  def thanks
    @fb_pixel_email = session[:fb_pixel_email]
    session.delete(:fb_pixel_email)
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
    @user = Spree::User.new
    @designer_registration = Spree::DesignerRegistration.new
    @designer_registration.user = @user
  end

  def upgrade_to_toom_all_access
    designer = Spree::DesignerRegistration.find(params[:id])
    respond_to do |format|
      if designer.update_columns(params[:designer_registration])
        Spree::Mailers::UpgradeMailer.upgrade(designer).deliver
        format.json {render json: {message: "Request for upgrade has been send"}, status: :ok}
      else
        format.json {render json: {message: "Error occured"}, status: :unprocessable_entity}
      end
    end
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
