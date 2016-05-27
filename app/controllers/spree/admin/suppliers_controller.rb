class Spree::Admin::SuppliersController < Spree::Admin::ResourceController

  def search
    Rails.logger.info "lolgfd"
    Rails.logger.info "ASDASDASDASDSADASDASDASDAS"
    if params[:ids]
      @suppliers = Spree::Supplier.where(:id => params[:ids].split(','))
    else
      @suppliers = Spree::Supplier.ransack(params[:q]).result
    end
    Rails.logger.info @suppliers.inspect
    respond_to do |format|
      format.json {render :action => "search", :layout => false}
    end

  end
 
end
