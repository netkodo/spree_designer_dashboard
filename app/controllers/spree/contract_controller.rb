class Spree::ContractController < Spree::StoreController

  def send_contract

    puts "TEST"
    puts "TEST"
    puts "TEST"
    puts "TEST"
    puts "TEST"

    respond_to do |format|
      if true
        format.json {render json: {message: "success"}, status: :ok}
      else
        format.json {render json: {message: "success"}, status: :unprocessable_entity}
      end
    end


  end

end



