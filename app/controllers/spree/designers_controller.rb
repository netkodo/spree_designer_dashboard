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

    @user.validate_description = true

    exceptions = []
    if params[:user].present?
      begin
        puts "\n\nCREATING CROPPED USER IMAGE\n\n"
        if params[:user][:user_images].present?
          to_destroy = @user.user_images.first if @user.user_images.present?
          base64 = params[:user][:user_images][:attachment]
          data = Base64.decode64(base64.split(',')[1])
          path = "#{Rails.root}/public/somefilename#{DateTime.now.to_i + rand(1000)}.png"
          file_img = File.new(path, 'wb')
          file_img.write data
          file_img.close
          f = File.open(path)
          @user_cropped =  @user.user_images.new(attachment: f)
          if @user_cropped.save
            File.delete(path)
            to_destroy.destroy
          end
        end
      rescue Exception => error
        File.delete(path)
        exceptions << "user image"
      end
      begin
        puts "\n\nCREATING ORIGINAL USER IMAGE\n\n"
        if params[:user][:user_image_original].present? and @user_cropped.present?
          base64 = params[:user][:user_image_original]
          data = Base64.decode64(base64.split(',')[1])
          path = "#{Rails.root}/public/somefilename#{DateTime.now.to_i + rand(1000)}.png"
          file_img = File.new(path, 'wb')
          file_img.write data
          file_img.close
          f = File.open(path)
          user_original = @user_cropped.build_user_original_image(attachment: f)
          if user_original.save
            File.delete(path)
          end
        end
      rescue Exception => error
        File.delete(path)
        puts error
      end

      begin
        puts "\n\nCRREATING CROPPED LOGO IMAGE\n\n"
        if params[:user][:logo_image].present?
          base64 = params[:user][:logo_image][:attachment]
          data = Base64.decode64(base64.split(',')[1])
          path = "#{Rails.root}/public/somefilename#{DateTime.now.to_i + rand(1000)}.png"
          file_img = File.new(path, 'wb')
          file_img.write data
          file_img.close
          f = File.open(path)
          @logo_cropped = @user.build_logo_image(attachment: f)
          if @logo_cropped.save
            File.delete(path)
          end
        end
      rescue Exception => error
        File.delete(path)
        exceptions << "logo image"
      end
      begin
        puts "\n\nCREATING ORIGINAL LOGO IMAGE\n\n"
        if params[:user][:logo_image_original].present? and @logo_cropped.present?
          base64 = params[:user][:logo_image_original]
          data = Base64.decode64(base64.split(',')[1])
          path = "#{Rails.root}/public/somefilename#{DateTime.now.to_i + rand(1000)}.png"
          file_img = File.new(path, 'wb')
          file_img.write data
          file_img.close
          f = File.open(path)
          logo_original =  @logo_cropped.build_logo_original_image(attachment: f)
          if logo_original.save
            File.delete(path)
          end
        end
      rescue Exception => error
        File.delete(path)
        puts error
      end

      params[:user] = params[:user].except!(:user_images, :logo_image, :user_image_original, :logo_image_original)

    end

    puts "!!!!!"
    puts "!!!!!"
    puts exceptions.awesome_inspect
    puts "!!!!!"
    puts "!!!!!"

    @user.user_ac_event_add("profile_setup_saved") if @user.active_campaign.blank? || !@user.active_campaign.first_room_added

    designer = Spree::DesignerRegistration.where(user_id:@user.id).first
    # boards = @user.boards.where(status: "published").count
    if @user.user_images.count == 1 and designer.status=="room designer" #boards > 0 and
      @user.update(:show_designer_profile => 1)
    else
      @user.update(:show_designer_profile => 0)
    end

    respond_to do |format|
      if @user.update_attributes(params[:user].permit!)
        @user.validate_description = false
        spree_current_user.update_column(:popup_my_profile, false) if spree_current_user.popup_my_profile
        session[:popup_portfolio] = true if spree_current_user.popup_portfolio

        redirect = designer_dashboard_path
        if exceptions.present?
          flash[:notice] = "Saving #{exceptions.join(',')} failed. Try again."
          redirect = my_profile_path
        end

        format.html { redirect_to redirect, :notice => 'Your profile was successfully updated.', location: url_for( designer_dashboard_path) }
        format.json { render json: {:location => redirect}, status: :ok }
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



