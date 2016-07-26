class Spree::PortfoliosController < Spree::StoreController

  def index

  end

  def portfolio_page
    if params[:filter].present?
      tab = []
      params[:filter].each do |f|
        tab << "#{f[0]}: #{f[1]}"
      end
      statement= "Spree::Portfolio.where(#{tab.join(',')})"

      tmp_portfolios = eval(statement).order('created_at DESC')#,board_id DESC
      if params[:page].present? and params[:page].to_i > 1
        obj = []
        (1..params[:page].to_i).each do |page|
          tmp_portfolios.page(page).per(3).each do |portfolio|
            obj << portfolio
          end
        end
      end

      @portfolios = tmp_portfolios.page(params[:page]).per(3)
      params[:cols].to_i > 768 ? @portfolios_ordering = Spree::Portfolio.portfolios_ordering(obj,3) : @portfolios_ordering = Spree::Portfolio.portfolios_ordering(obj,2)
    else
      tmp_portfolios = Spree::Portfolio.all.order('created_at DESC')
      if params[:page].present? and params[:page].to_i > 1
        obj = []
        (1..params[:page].to_i).each do |page|
          tmp_portfolios.page(page).per(3).each do |portfolio|
            obj << portfolio
          end
        end
      end
      # tmp_portfolios = Spree::Portfolio.all.order('created_at DESC')
      @portfolios = tmp_portfolios.page(params[:page]).per(3)
      params[:cols].to_i > 768 ? @portfolios_ordering = Spree::Portfolio.portfolios_ordering(obj,3) : @portfolios_ordering = Spree::Portfolio.portfolios_ordering(obj,2)
    end
    render "portfolio_page", layout: false
  end

  def search
    @colors = Hash.new(0)
    @designers = Hash.new(0)
    @room_type = Hash.new(0)
    @room_style = Hash.new(0)

    if params[:filter].present?
      tab = []
      params[:filter].each do |f|
        tab << "#{f[0]}: #{f[1]}"
      end
      statement= "Spree::Portfolio.where(#{tab.join(',')})"

      tmp_portfolios = eval(statement).order('created_at DESC')#,board_id DESC
      @portfolios = tmp_portfolios.page(params[:page]).per(3)
      params[:cols].to_i > 768 ? @portfolios_ordering = Spree::Portfolio.portfolios_ordering(@portfolios,3) : @portfolios_ordering = Spree::Portfolio.portfolios_ordering(@portfolios,2)
      colors = tmp_portfolios.map { |c| [c.wall_color,c.wall_color]}
      room_type = tmp_portfolios.map { |r| [r.room_types.name,r.room_types.id]}
      room_style = tmp_portfolios.map { |s| [s.room_styles.name,s.room_styles.id]}
      designers = tmp_portfolios.map {|d| [d.user.full_name,d.user.id]}
    else
      tmp_portfolios = Spree::Portfolio.all.order('created_at DESC')
      @portfolios = tmp_portfolios.page(params[:page]).per(3)
      params[:cols].to_i > 768 ? @portfolios_ordering = Spree::Portfolio.portfolios_ordering(@portfolios,3) : @portfolios_ordering = Spree::Portfolio.portfolios_ordering(@portfolios,2)
      colors = tmp_portfolios.map { |c| [c.wall_color,c.wall_color]}
      room_type = tmp_portfolios.map { |r| [r.room_types.name,r.room_types.id]}
      room_style = tmp_portfolios.map { |s| [s.room_styles.name,s.room_styles.id]}
      designers = tmp_portfolios.map {|d| [d.user.full_name,d.user.id]}
    end

    colors.each do |v|
      @colors[v] += 1
    end

    designers.each do |v|
      @designers[v] += 1
    end

    room_type.each do |v|
      @room_type[v] += 1
    end

    room_style.each do |v|
      @room_style[v] += 1
    end

    render "spree/portfolios/search",layout: false
  end

  def portfolio
    @portfolio = Spree::Portfolio.new
    # @colors = Spree::Color.all.map {|c| [c.name,c.id]}
    @colors = Spree::Board.color_categories
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
    w=Paperclip::Geometry.from_file(@portfolio.portfolio_image(:large)).width
    w >= params[:width].to_i ? @width=params[:width].to_i-20 : @width=w
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



