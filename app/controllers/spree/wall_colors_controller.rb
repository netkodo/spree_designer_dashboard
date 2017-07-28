class Spree::WallColorsController < Spree::StoreController

  before_filter :set_board

  def wall_colors
    @wall_colors = @board.wall_colors
    respond_to do |format|
      format.json   {render :layout => false}
    end
  end

  def destroy
    @wall_color = @board.wall_colors.find_by_slug(params[:slug])
    if @wall_color.destroy
      render json: {message: "success"}, staus: :ok
    else
      render json: {message: "error"}, staus: :unprocessable_entity
    end

  end

  private

  def set_board
    @board = Spree::Board.find(params[:id])
  end

end