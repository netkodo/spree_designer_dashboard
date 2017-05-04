class Spree::ProjectHistoryController < Spree::StoreController

  def destroy
    project_history = Spree::ProjectHistory.find(params[:id])
    respond_to do |format|
      if project_history.destroy
        format.json {render json: {message: "success"}, status: :ok}
      else
        format.json {render json: {message: "error"}, status: :unprocessable_entity}
      end
    end
  end

end