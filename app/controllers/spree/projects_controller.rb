class Spree::ProjectsController < Spree::StoreController

  before_filter :require_authentication
  before_filter :check_owner, except: [:index, :new, :create, :create_project] #:update, :edit, :show, :destroy, :close_open, :index

  def index
    params[:project_id].present? ? @selected_project = Spree::Project.where(user_id: spree_current_user.id).find(params[:project_id]) : @selected_project = nil
    @projects = Spree::Project.close.where(user_id: spree_current_user.id).order("project_name asc")
    @boards = Spree::Board.private_by_user(spree_current_user.id)
  end

  def new
    @project = Spree::Project.new
  end

  def show
    @project = Spree::Project.find(params[:id])
    @project_history = @project.project_histories.order("created_at desc")
  end

  def create
    @project = Spree::Project.new(project_params)

    if @project.save
      # redirect_to edit_project_path(@project)
      redirect_to project_path(@project)
    else
      redirect_to projects_path
    end
  end

  def create_project
    @project = Spree::Project.new
    respond_to do |format|
      if @project.save
        format.json { render json: {message: 'success', location: edit_project_path(id: @project, step: 1)}, status: :created}
      else
        format.json {render json: {message: 'error'}, status: :unprocessable_entity}
      end
    end
  end

  def edit
    @project = Spree::Project.find(params[:id])
    @project_history = @project.project_histories.order("created_at desc")
  end

  def update
    @project = Spree::Project.find(params[:id])
    respond_to do |format|
      if @project.update(project_params)
        @project.contract.destroy if @project.contract.present? and @project.contract.signed?
        format.html { redirect_to designer_dashboard_path(id: @project.id, private: true) }
        format.json { render json: {message: "success"}, status: :ok }
        format.js { render json: {message: "success"}, status: :ok }
      else
        format.html { redirect_to designer_dashboard_path(id: @project.id, private: true) }
        format.json { render json: {message: "error"}, status: :unprocessable_entity }
        format.js { render json: {message: "error"}, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @project = Spree::Project.find(params[:id])
    if @project.destroy
      render json: {location: projects_path}
    else
      render json: {location: projects_path}
    end
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

    def check_owner
      unless spree_current_user.present? and spree_current_user.projects.pluck(:id).include?(params[:id].to_i)
        flash[:error] = "Access denied"
        redirect_to root_path
      end
    end

    def project_params
      params.require(:project).permit(:user_id, :project_name, :description, :address1, :address2, :city, :state, :zip_code, :email, :phone, :rate_type, :rate, :customer_billing_cycle, :charge_percentage, :charge, :charge_on, :status, :pass_discount, :discount_amount, :upfront_deposit, :deposit_amount)
    end
end
