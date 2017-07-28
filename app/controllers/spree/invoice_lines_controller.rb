class Spree::InvoiceLinesController < Spree::StoreController
  require 'mandrill'

  def save_invoice
    if params[:invoice].present?
      params[:invoice].each do |key,val|
        check_prod = Spree::InvoiceLine.find_by(board_product_id: key)
        if check_prod.present?
          update_hash={}
          val.except('custom').each do |k,v|
            update_hash[k.snakecase]=v
          end
          # Rails.logger.info update_hash
          check_prod.update_columns(update_hash)
          # Rails.logger.info "update hash"
        else
          new = Spree::InvoiceLine.new(board_product_id: key)
          val.except('custom').each do |k,v|
            new[k.snakecase.to_sym]=v
          end
          new.save
          # Rails.logger.info new.inspect
        end
      end
    end

    respond_to do |format|
      if true
        Spree::BoardHistory.create(user_id: params[:user_id], board_id: params[:board_id], action: "invoice_edit")
        format.json{render json: {},status: :ok}
      else
        format.json{render json: {},status: :unprocessable_entity}
      end
    end
  end

  def private_invoice
    @board = Spree::Board.find(params[:id])
    project = @board.project
    @board_products = @board.board_products#.map{|x| x.product.present? ? x.product : x.custom_item}
    @subtotals = Spree::BoardProduct.calculate_subtotal(@board_products,false,project.pass_discount,project.discount_amount)
    respond_to do |format|
      if @board_products.present?
        format.html{render layout: false, status: :ok}
      else
        format.html{render layout: false, status: :unprocessable_entity}
      end
    end
  end

  def send_invoice_email
    board = Spree::Board.find(params[:id])
    project = board.project
    user = board.designer
    designer = user.designer_registrations.first
    board_products = board.board_products#.map{|x| x.product.present? ? x.product : x.custom_item}
    subtotal = Spree::BoardProduct.calculate_subtotal(board_products,true,project.pass_discount,project.discount_amount)
    total = Spree::BoardProduct.calculate_subtotal(board_products,true,project.pass_discount,project.discount_amount)

    taxcloud=board.calculate_tax

    content = render_to_string('/spree/invoice_lines/pdf_invoice_content.html.erb',layout: false, locals: {designer: designer, user: user, board: board, board_products: board_products,subtotal: subtotal, tax: taxcloud.tax_amount, total: total, project: project})
    #+taxcloud.tax_amount

    pdf = WickedPdf.new.pdf_from_string(content,{orientation: 'Landscape',margin: {top:10,bottom:10,left:0,right:0}})
    save_path = Rails.root.join('public',"filename-#{Time.now.to_i}.pdf")
    File.open(save_path, 'wb') do |file|
      file << pdf
    end

    pdf_file = File.open(save_path,"r")

    respond_to do |format|
      if Spree::Mailers::ContractMailer.invoice(user.email,user,save_path).deliver
        Spree::ProjectHistory.create(action: "invoice_sent",project_id: board.project.id, pdf: pdf_file)
        Spree::BoardHistory.create(user_id: user.id, board_id: board.id, action: "invoice_email")
        File.delete(save_path) if File.exist?(save_path)
        format.json {render json: {:message => "ok"}, status: :ok}
      else
        format.json {render json: {:message => "error"},status: :unprocessable_entity}
      end
    end

  end

  def show_invoice_email
    board = Spree::Board.last
    designer = board.designer
    board_products = board.board_products#.map{|x| x.product.present? ? x.product : x.custom_item}
    subtotal = Spree::BoardProduct.sum_items(board_products)
    total = Spree::BoardProduct.sum_items(board_products)

    taxcloud=board.calculate_tax

    # board_products = board.board_products.select{|x| x.product_id.present?}.group_by(:product_id)
    # custom_products = board.board_products.select{|x| x.custom_item_id.present?}.group_by(:custom_item_id)
    respond_to do |format|
      format.html {render '/spree/invoice_lines/pdf_invoice_content.html.erb',layout: false, locals: {designer: designer, board: board, board_products: board_products,subtotal: subtotal, tax: taxcloud.tax_amount, total: total+taxcloud.tax_amount}}
      #custom_products:custom_products
    end
  end

end



