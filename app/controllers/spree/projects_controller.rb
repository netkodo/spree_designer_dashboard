class Spree::ProjectsController < Spree::StoreController

  def index
    params[:project_id].present? ? @selected_project = Spree::Project.where(user_id: spree_current_user.id).find(params[:project_id]) : @selected_project = nil
    @projects = Spree::Project.where(user_id: spree_current_user.id).order("project_name asc")
    @boards = Spree::Board.private_by_user(spree_current_user.id)
  end

  def new
    @project = Spree::Project.new
  end

  def create
    @project = Spree::Project.new(project_params)

    if @project.save
      # redirect_to edit_project_path(@project)
      redirect_to projects_path(project_id: @project.id)
    else
      redirect_to projects_path
    end
  end

  def edit
    @project = Spree::Project.find(params[:id])
    @project_history = @project.project_histories.order("created_at desc")
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

  def close_open
    @project = Spree::Project.find(params[:id])
    respond_to do |format|
      if @project.update(project_params)
        format.json {render json: {message: 'Project updated'}, status: :ok}
      else
        format.json {render json: {message: 'error'}, status: :unprocessable_entity}
      end
    end
  end


  private

    def project_params
      params.require(:project).permit(:user_id, :project_name, :description, :address1, :address2, :city, :state, :zip_code, :email, :phone, :rate_type, :rate, :customer_billing_cycle, :charge_percentage, :charge, :charge_on, :status, :pass_discount, :discount_amount, :upfront_deposit, :deposit_amount)
    end
end
