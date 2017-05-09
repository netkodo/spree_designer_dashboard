class Spree::WallColorsController < Spree::StoreController

  before_filter :set_board

  def wall_colors
    @wall_colors = @board.wall_colors
    respond_to do |format|
      format.json   {render :layout => false}
    end
  end

  private

  def set_board
    @board = Spree::Board.find(params[:id])
  end

end