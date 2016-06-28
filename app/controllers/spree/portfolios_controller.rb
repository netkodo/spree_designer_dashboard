class Spree::PortfoliosController < Spree::StoreController

  def portfolio
    @portfolio = Spree::Portfolio.new
    @colors = Spree::Color.all.map {|c| [c.name,c.id]}
    rooms = Spree::Taxonomy.where(:name => 'Rooms').first().root.children.select { |child| Spree::Board.available_room_taxons.include?(child.name) }
    styles = Spree::Taxonomy.where(:name => 'Styles').first().root.children
    @room_type = rooms.map {|r| [r.name,r.id]}
    @room_style = styles.map {|s| [s.name,s.id]}

    @portfolios = spree_current_user.portfolios
  end

  def create_portfolio
    # checking params because if we wont cut portfolio_image it wont pass validation even if its empty string
    !portfolio_params[:portfolio_image].present? ? x = portfolio_params.except(:portfolio_image) : x = portfolio_params
    @portfolio = Spree::Portfolio.new(x)
    respond_to do |format|
      if @portfolio.save
        format.html {redirect_to portfolio_path}
        format.json {render json: {location: portfolio_path}, status: :ok}
      else
        format.html {redirect_to portfolio_path}
        format.json {render json: @portfolio.errors, status: :unprocessable_entity}
      end
    end
  end

  def portfolio_content
    @portfolio = Spree::Portfolio.find(params[:portfolio_id])
  end

  def add_portfolio_favorite
    portfolio = Spree::PortfolioFavorite.new(user_id: params[:user_id],portfolio_id: params[:portfolio_id])
    respond_to do |format|
      if portfolio.save
        format.json {render json: {}, status: :ok}
      else
        format.json {render json: portfolio.errors, status: :unprocessable_entity}
      end
    end
  end

  def remove_portfolio_favorite
    portfolio = Spree::PortfolioFavorite.find_by(user_id: params[:user_id],portfolio_id: params[:portfolio_id])
    respond_to do |format|
      if portfolio.destroy
        format.json {render json: {}, status: :ok}
      else
        format.json {render json: portfolio.errors, status: :unprocessable_entity}
      end
    end
  end

  private

    def portfolio_params
      params.require(:portfolio).permit(:user_id,:name,:room_type,:style,:wall_color,:portfolio_image)
    end
end



