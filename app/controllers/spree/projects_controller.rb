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
    pending = @project.project_histories.find_by_action("pending_invoice")
    @project_history = @project.project_histories.order("created_at desc").select{|x| x.action != "pending_invoice"}
    @project_history.unshift(pending) if pending.present?
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
    @project = Spree::Project.create(user_id: spree_current_user.id)
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
    current_step = params[:current_step] || 3
    @project = Spree::Project.find(params[:id])
    respond_to do |format|
      @project.assign_attributes(eval("project_params_step#{current_step}"))
      if @project.changed?
        if @project.save #update(eval("project_params_step#{current_step}"))
          @project.contract.destroy if @project.contract.present? and @project.contract.signed?

          ph = @project.project_histories.where("action LIKE 'contract_%'").first
          ph.update_attribute(:action, "contract_changed") if ph.present?

          format.html { redirect_to project_path(@project) }
          format.json { render json: {message: "success"}, status: :ok }
          format.js { render json: {message: "success"}, status: :ok }
        else
          format.html { redirect_to project_path(@project) }
          format.json { render json: {message: "error"}, status: :unprocessable_entity }
          format.js { render json: {message: "error"}, status: :unprocessable_entity }
        end
      else
        format.html { redirect_to project_path(@project) }
        format.json { render json: {message: "no changes"}, status: :ok }
        format.js { render json: {message: "no changes"}, status: :ok }
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

  def start_without_contract
    ph = Spree::ProjectHistory.create(project_id: params[:id], action: "pending_invoice")
    respond_to do |format|
      if ph.save
        history_item = render_to_string(partial: 'spree/projects/project_history_item', locals: {ph: ph}, formats: ['html'] )
        format.json {render json: {message: 'created', history_item: history_item}, status: :ok}
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

    def project_params_step1
      params.require(:project).permit(:user_id, :project_name, :description, :address1, :address2, :city, :state, :zip_code, :email, :phone)
    end

    def project_params_step2
      params.require(:project).permit(:user_id, :rate_type, :rate, :upfront_deposit, :deposit_amount, :customer_billing_cycle)
    end

    def project_params_step3
      params.require(:project).permit(:user_id, :pass_discount, :discount_amount, :charge, :charge_on, :charge_percentage)
      # , :status
    end

    # def project_params
    #   params.require(:project).permit(:user_id, :project_name, :description, :address1, :address2, :city, :state, :zip_code, :email, :phone, :rate_type, :rate, :customer_billing_cycle, :charge_percentage, :charge, :charge_on, :status, :pass_discount, :discount_amount, :upfront_deposit, :deposit_amount)
    # end
end
