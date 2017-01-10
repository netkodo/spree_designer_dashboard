class Spree::ContractsController < Spree::StoreController

  def new
    project = Spree::Project.includes(:contract).find(params[:id])
    contract = project.contract
    if contract.present?
      if contract.designer_signed and !contract.client_signed
        redirect_to edit_contract_path(project, contract)
      else
        redirect_to contract_path(project, contract)
      end
    else
      @contract = Spree::Contract.new
    end
  end

  def create
    # designer
    path_d = "#{Rails.root}/public/sign#{DateTime.now.to_i + rand(1000)}.png"
    data_d = Base64.decode64(params[:contract][:signature_designer_code]['data:image/png;base64,'.length .. -1])
    file_img_d = File.new(path_d, 'wb')
    file_img_d.write data_d
    file_img_d.close
    file_img_d = File.open(path_d)

    # client
    # path_c = "#{Rails.root}/public/sign#{DateTime.now.to_i + rand(1000)}.png"
    # data_c = Base64.decode64(params[:contract][:signature_client_code]['data:image/png;base64,'.length .. -1])
    # file_img_c = File.new(path_c, 'wb')
    # file_img_c.write data_c
    # file_img_c.close
    # file_img_c = File.open(path_c)

    @contract = Spree::Contract.new(contract_params)
    # @contract.client_sign = file_img_c
    @contract.designer_sign = file_img_d

    respond_to do |format|
      if @contract.save
        @contract.update_column(:designer_signed, true)
        @contract.update_column(:token, SecureRandom.uuid) unless @contract.token.present?
        # File.delete(file_img_c)
        File.delete(file_img_d)
        format.json {render json: {message: 'success', location: projects_path}, status: :ok}
      else
        # File.delete(file_img_c)
        File.delete(file_img_d)
        format.json {render json: {message: 'error'}, status: :unprocessable_entity}
      end
    end
  end

  def preview_sign_contract
    @contract = Spree::Contract.find_by(token: params[:token])
    if @contract.designer_signed and @contract.client_signed
      flash[:alert] = "You have already signed that contract"
      redirect_to root_path
    end
  end

  def sign_contract
    @contract = Spree::Contract.find_by(token: params[:token])

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
    puts @contract.inspect
    # params[:cid] = @contract
    puts "aaa"
    puts params.inspect
    puts "aaa"
  end

  def update

  end

  private

    def contract_params
      params.require(:contract).permit(:designer_name, :client_name, :project_id)
    end
end
