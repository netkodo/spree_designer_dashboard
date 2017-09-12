class Spree::ProjectHistoryController < Spree::StoreController

  before_filter :check_owner, only: [:destroy, :send_invoice, :edit_ready_invoice]

  def destroy
    project = Spree::Project.find(params[:id])
    project_history = project.project_histories.find(params[:ph])
    project_history.project_invoice_lines.each{
        |x| x.custom ? x.destroy : x.update_columns(project_history_id: nil, included: false)
    } if project_history.project_invoice_lines.present?
    respond_to do |format|
      if project_history.destroy
        format.json {render json: {message: "success"}, status: :ok}
      else
        format.json {render json: {message: "error"}, status: :unprocessable_entity}
      end
    end
  end

  def edit_ready_invoice
    @show = true
    @project = Spree::Project.find(params[:id])
    @ph = params[:ph]
    invoice_history = @project.project_histories.find(params[:ph])
    @project_invoice_lines = invoice_history.project_invoice_lines.order(:date)

    render "spree/project_invoice_lines/edit_invoice"
  end

  def edit_custom_invoice
    @show = true
    @project = Spree::Project.find(params[:id])
    @ph = params[:ph]
    invoice_history = @project.project_histories.find(params[:ph])
    @project_invoice_lines = invoice_history.project_invoice_lines.order(:date)

    render "spree/project_invoice_lines/edit_custom_invoice"
  end

  def send_invoice
    project = Spree::Project.find(params[:id])
    invoice_history = project.project_histories.find(params[:ph])

    respond_to do |format|
      if Spree::Mailers::ContractMailer.invoice_for_client(project.user.email,project.user,project,invoice_history.pdf.url).deliver
        
        invoice_history.update_columns(action: "invoice_sent") if invoice_history.action != "invoice_sent"
        history_item = render_to_string(partial: 'spree/projects/project_history_item', locals: {ph: invoice_history}, formats: ['html'] )

        format.json {render json: {message: "success", history_item: history_item, history_id: invoice_history.id}, status: :ok}
      else
        format.json {render json: {message: "error"}, status: :unprocessable_entity}
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

end