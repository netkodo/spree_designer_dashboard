class Spree::ContractsController < Spree::StoreController

  def new
    project = Spree::Project.includes(:contract).find(params[:id])
    contract = project.contract
    if contract.present?
      if contract.designer_signed and contract.client_signed
        redirect_to contract_path(project, contract)
      else
        redirect_to edit_contract_path(project, contract)
      end
    else
      @contract = Spree::Contract.new
    end
  end

  def create
    @contract = Spree::Contract.joins(:project).new(contract_params)

    respond_to do |format|
      if @contract.save
        @contract.update_column(:token, SecureRandom.uuid) unless @contract.token.present?
        if params[:button] == 'true'
          Spree::Contract.send_contract_email(@contract.project.email, "contract-email", "You have contract from designer (#{@contract.designer_name}) to sign", "https://www.scoutandnimble.comsign_contract/#{@contract.token}")
        end
        format.json {render json: {message: 'success', location: projects_path}, status: :ok}
      else
        format.json {render json: {message: 'error'}, status: :unprocessable_entity}
      end
    end
  end

  def preview_sign_contract
    @contract = Spree::Contract.find_by(token: params[:token])
    if @contract.client_signed
      flash[:alert] = "You have already signed that contract"
      redirect_to root_path
    end
  end

  def sign_contract
    @contract = Spree::Contract.includes(:project).find_by(token: params[:token])

    path_c = "#{Rails.root}/public/sign#{DateTime.now.to_i + rand(1000)}.png"
    data_c = Base64.decode64(params[:contract][:signature_client_code]['data:image/png;base64,'.length .. -1])
    file_img_c = File.new(path_c, 'wb')
    file_img_c.write data_c
    file_img_c.close
    file_img_c = File.open(path_c)

    @contract.client_sign = file_img_c

    respond_to do |format|
      if @contract.save
        @contract.update_column(:client_signed, true)
        Spree::Contract.send_contract_email(@contract.project.user.email, "contract-email", "Contract has been signed by client #{@contract.project.project_name}", "")
        File.delete(file_img_c)
        flash[:alert] = "You have successfully signed contract"
        format.json {render json: {message: 'success', location: root_path }, status: :ok}
      else
        File.delete(file_img_c)
        format.json {render json: {message: 'error'}, status: :unprocessable_entity}
      end
    end
  end

  def show
    @contract = Spree::Contract.find(params[:cid])
  end

  def edit
    @contract = Spree::Contract.find(params[:cid])
    if @contract.client_signed and @contract.designer_signed
      redirect_to contract_path(@contract.project, @contract)
    end
  end

  def update

    @contract = Spree::Contract.includes(:project).find(params[:cid])

    # designer sign
    check_sign = params[:contract][:signature_designer_code].present? and @contract.client_signed
    if check_sign
      path_d = "#{Rails.root}/public/sign#{DateTime.now.to_i + rand(1000)}.png"
      data_d = Base64.decode64(params[:contract][:signature_designer_code]['data:image/png;base64,'.length .. -1])
      file_img_d = File.new(path_d, 'wb')
      file_img_d.write data_d
      file_img_d.close
      file_img_d = File.open(path_d)
      @contract.designer_sign = file_img_d
    end

    @contract.attributes=contract_params

    respond_to do |format|
      if @contract.save
        if params[:button].present? and params[:button] == 'true'
          Spree::Contract.send_contract_email(@contract.project.email, "contract-email", "You have contract from designer (#{@contract.designer_name}) to sign", "https://www.scoutandnimble.com/sign_contract/#{@contract.token}")
        end

        if check_sign
          @contract.update_column(:designer_signed, true)
          File.delete(file_img_d)
        end
        format.json {render json: {message: 'success', location: projects_path}, status: :ok}
      else
        format.json {render json: {message: 'error'}, status: :unprocessable_entity}
      end
    end
  end

  def send_contract

    @project = Spree::Project.find(params[:id])

    contract = render_to_string('/spree/contracts/contract_content.html.erb',layout: false, locals: {contract: @project.contract, project: @project, designer: @project.user.designer_registrations.first, user: @project.user})

    pdf = WickedPdf.new.pdf_from_string(contract)
    save_path = Rails.root.join('public',"filename-#{Time.now.to_i}.pdf")
    File.open(save_path, 'wb') do |file|
      file << pdf
    end

    if Rails.env == "production" or Rails.env == "staging"
      mail_to = "sam@scoutandnimble.com"
    else
      mail_to = "dniedzialkowski@netkodo.com"
    end
    from_addr = "designer@scoutandnimble.com"
    @project.send_contract(from_addr,mail_to,"CONTRACT",pdf)

    pdf_file = File.open(save_path,"r")

    respond_to do |format|
      if true
        history = Spree::ProjectHistory.create(action: "contract_sent",project_id: @project.id, pdf: pdf_file)
        history_item = render_to_string(partial: 'spree/projects/project_history_item', locals: {ph: history}, formats: ['html'] )
        File.delete(save_path) if File.exist?(save_path)
        format.json {render json: {message: "success", history_item: history_item}, status: :ok}
      else
        format.json {render json: {message: "success"}, status: :unprocessable_entity}
      end
    end


  end


  def preview_contract
    if params[:id] == "-1"
      params.permit!
      user = Spree::User.find(params[:project][:user_id])
      designer = user.designer_registrations.first
      project = Spree::Project.new(params[:project])
    else
      project = Spree::Project.find(params[:id])
      user = project.user
      designer = user.designer_registrations.first
    end

    respond_to do |format|
      format.pdf {render pdf: "pdf", template: '/spree/contracts/contract_content.html.erb', locals: {contract: project.contract, project: project, designer: designer, user: user}, user_style_sheet: 'spree/frontend/styles.css'}
    end


  end

  private

    def contract_params
      params.require(:contract).permit(:designer_name, :client_name, :client_email, :project_id)
    end
end
