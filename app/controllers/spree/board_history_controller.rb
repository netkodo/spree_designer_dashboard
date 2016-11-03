class Spree::BoardHistoryController < Spree::StoreController

  def board_history
    @history = Spree::BoardHistory.where(board_id: params[:board_id],user_id: params[:user_id])
    render "board_history", layout: false
  end

  def create
    new_history=Spree::BoardHistory.new(board_history_params)

    respond_to do |format|
      if new_history.save
        format.json{render json: new_history,status: :ok}
      else
        format.json{render json: new_history.errors, status: :unprocessable_entity}
      end
    end
  end

  private

  def board_history_params
    params.require(:board_history).permit(:user_id, :board_id, :action)
  end

end



