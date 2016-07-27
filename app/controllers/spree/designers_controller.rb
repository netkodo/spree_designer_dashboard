class Spree::DesignersController < Spree::StoreController
  before_filter :require_authentication, :only => [:update]
  before_filter :set_section

  impressionist :actions => [:show]

  def set_section
    @selected_section = "designers"
  end

  def index
    @designers = Spree::User.published_designers().order("created_at desc")
  end

  def tutorials

  end

  def update
    @user = spree_current_user

    if params[:user].present?
      if params[:user][:user_images].present?
        @user.user_images.destroy_all
        base64 = (params[:user][:user_images][:attachment])
        data = Base64.decode64(base64['data:image/png;base64,'.length .. -1])
        file_img = File.new("#{Rails.root}/public/somefilename#{DateTime.now.to_i + rand(1000)}.png", 'wb')
        file_img.write data
        @image =  @user.user_images.new(attachment: file_img)
        if @image.save
          File.delete(file_img)
        end
      end

      if params[:user][:logo_image].present?
        base64 = (params[:user][:logo_image][:attachment])
        data = Base64.decode64(base64['data:image/png;base64,'.length .. -1])
        file_img = File.new("#{Rails.root}/public/somefilename#{DateTime.now.to_i + rand(1000)}.png", 'wb')
        file_img.write data
        if @user.create_logo_image(attachment: file_img)
          File.delete(file_img)
        end
      end

      params[:user] = params[:user].except!(:user_images, :logo_image)

    end

    designer = Spree::DesignerRegistration.where(user_id:@user.id).first
    boards = @user.boards.where(status: "published").count
    if boards > 0 and @user.user_images.count == 1 and designer.status="room designer"
      @user.update(:show_designer_profile => 1)
    else
      @user.update(:show_designer_profile => 0)
    end

    respond_to do |format|
      if @user.update_attributes(params[:user].permit!)
        format.html { redirect_to designer_dashboard_path(format: 'html'), :notice => 'Your profile was successfully updated.', location: url_for( designer_dashboard_path) }
        format.json { render json: {:location => designer_dashboard_path}, status: :ok }
      else
        format.html { redirect_to my_profile_path(format: 'html'), :notice => 'There was an error and your profile was not updated.', location: url_for( my_profile_path) }
        format.json { render json: @user.errors,status: :unprocessable_entity }
      end
    end
  end

  def signup
    @designer = Spree::User.new
  end

  def show
    @designer = Spree::User.is_active_designer().where(:username => params[:username]).first
    if @designer.present?
      # @portfolio_boards = @designer.boards.map { |b| b if b.portfolio.present? }.delete_if(&:blank?)
      @portfolios = @designer.portfolios
      @products = []
      @products = @designer.products.available_through_published_boards if @designer.present?
      render :action => "show"
    else
      raise ActionController::RoutingError.new('Not Found')
    end
  end

  private
  def designer_params
    params.require(:user).permit(:first_name, :last_name, :description, :company_name, :website_url, :location, :blog_url, :email, :password, :password_confirmation,
                                 :is_discount_eligible, :is_beta_user, :can_add_boards, :designer_featured_starts_at, :designer_featured_ends_at, :designer_featured_position,
                                 :supplier_id, :marketing_images_attributes, :feature_image_attributes, :bill_address_id, :ship_address_id,
                                 :social_facebook, :social_twitter, :social_instagram, :social_pinterest, :social_googleplus, :social_linkedin, :social_tumblr,
                                 :username, :designer_quote, :marketing_images, :profile_display_name, :designer_commission, :show_designer_profile, :feature_image,
                                 :user_images_attributes,:logo_image)
  end

end



