class Spree::Admin::DesignerRegistrationsController < Spree::Admin::ResourceController


 
  def index
    @designer_registrations = Spree::DesignerRegistration.all.page(params[:page]).per(params[:per_page] || Spree::Config[:orders_per_page])
  end


  def room_designers
    Rails.logger.info "dasdasdasdasd"
    @designer_registrations = Spree::DesignerRegistration.where(status: "room designer").page(params[:page]).per(params[:per_page] || Spree::Config[:orders_per_page])

    # render 'index'
  end

  def trade_program
    @designer_registrations = Spree::DesignerRegistration.where(status: "to the trade designer").page(params[:page]).per(params[:per_page] || Spree::Config[:orders_per_page])
    # render :index
  end
 
  # redirect to the edit action after create
  #  create.response do |wants|
  #    wants.html { redirect_to edit_admin_fancy_thing_url( @fancy_thing ) }
  #  end
  #  
  #  # redirect to the edit action after update
  #  update.response do |wants|
  #    wants.html { redirect_to edit_admin_fancy_thing_url( @fancy_thing ) }
  #  end

end