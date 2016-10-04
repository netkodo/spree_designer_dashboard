class Spree::InvoiceLinesController < Spree::StoreController

  def save_invoice
    if params[:invoice].present?
      params[:invoice].each do |key,val|
        check_prod = Spree::InvoiceLine.find_by(board_id: params[:board_id],product_id:key)
        if check_prod.present?
          update_hash={}
          val.each do |k,v|
            update_hash[k.snakecase]=v
          end
          Rails.logger.info update_hash
          check_prod.update_columns(update_hash)
          Rails.logger.info "aa"
        else
          custom_data=Spree::InvoiceLine.new(board_id:params[:board_id],product_id: key)
          val.each do |k,v|
            custom_data[k.snakecase.to_sym]=v
          end
          custom_data.save
          Rails.logger.info custom_data.inspect
        end
      end
    end

    respond_to do |format|
      if true
        format.json{render json: {},status: :ok}
      else
        format.json{render json: {},status: :unprocessable_entity}
      end
    end
  end

end



