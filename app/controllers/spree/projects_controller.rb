class Spree::ProjectsController < Spree::StoreController

  def index
    @projects = Spree::Project.where(user_id: spree_current_user.id).order("project_name asc")
  end

  def new
    @project = Spree::Project.new
  end

  def create
    @project = Spree::Project.new(project_params)

    if @project.save
      redirect_to "/projects"
    else

    end
  end

  def edit
    @project = Spree::Project.find(params[:id])
  end

  def update
    @project = Spree::Project.find(params[:id])
    if @project.update(project_params)
      redirect_to "/projects"
    else

    end
  end

  def edit_details

  end


  private

    def project_params
      params.require(:project).permit(:user_id, :project_name, :address1, :address2, :city, :state, :zip_code, :email, :phone, :rate_type, :rate, :customer_billing_cycle, :charge_percentage, :charge, :charge_on)
    end
end
