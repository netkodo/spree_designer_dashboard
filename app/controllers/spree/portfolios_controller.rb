class Spree::PortfoliosController < Spree::StoreController

  def index

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

      @portfolios = eval(statement).order('created_at DESC')#,board_id DESC
      params[:cols].to_i > 768 ? @portfolios_ordering = Spree::Portfolio.portfolios_ordering(@portfolios,3) : @portfolios_ordering = Spree::Portfolio.portfolios_ordering(@portfolios,2)
      colors = @portfolios.map { |c| [c.wall_color,c.wall_color]}
      room_type = @portfolios.map { |r| [r.room_types.name,r.room_types.id]}
      room_style = @portfolios.map { |s| [s.room_styles.name,s.room_styles.id]}
      designers = @portfolios.map {|d| [d.user.full_name,d.user.id]}
    else
      @portfolios = Spree::Portfolio.all.order('created_at DESC')
      params[:cols].to_i > 768 ? @portfolios_ordering = Spree::Portfolio.portfolios_ordering(@portfolios,3) : @portfolios_ordering = Spree::Portfolio.portfolios_ordering(@portfolios,2)
      colors = @portfolios.map { |c| [c.wall_color,c.wall_color]}
      room_type = @portfolios.map { |r| [r.room_types.name,r.room_types.id]}
      room_style = @portfolios.map { |s| [s.room_styles.name,s.room_styles.id]}
      designers = @portfolios.map {|d| [d.user.full_name,d.user.id]}
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
    if spree_current_user and (spree_current_user.is_beta_user? or spree_current_user.is_designer?)
      @portfolio = Spree::Portfolio.new
      # @colors = Spree::Color.all.map {|c| [c.name,c.id]}
      @colors = Spree::Board.color_categories
      rooms = Spree::Taxonomy.where(:name => 'Rooms').first().root.children.select { |child| Spree::Board.available_room_taxons.include?(child.name) }
      styles = Spree::Taxonomy.where(:name => 'Styles').first().root.children
      @room_type = rooms.map {|r| [r.name,r.id]}
      @room_style = styles.map {|s| [s.name,s.id]}

      @portfolios = spree_current_user.portfolios
    else
      redirect_to "/"
    end
  end

  def edit_portfolio
    @colors = Spree::Board.color_categories
    rooms = Spree::Taxonomy.where(:name => 'Rooms').first().root.children.select { |child| Spree::Board.available_room_taxons.include?(child.name) }
    styles = Spree::Taxonomy.where(:name => 'Styles').first().root.children
    @room_type = rooms.map {|r| [r.name,r.id]}
    @room_style = styles.map {|s| [s.name,s.id]}

    @portfolio = Spree::Portfolio.find(params[:id])
  end

  def update_portfolio
    @portfolio = Spree::Portfolio.find(params[:portfolio][:id])
    !portfolio_params[:portfolio_image].present? ? x = portfolio_params.except(:portfolio_image) : x = portfolio_params
    respond_to do |format|
      if @portfolio.update(x)
        if @portfolio.board.present?
          board = @portfolio.board
          board.update(room_id: params[:portfolio][:room_type],style_id: params[:portfolio][:style])
        end
        format.html {redirect_to portfolio_path}
        format.json {render json: {location: portfolio_path}, status: :ok}
      else
        format.html {redirect_to portfolio_path}
        format.json {render json: @portfolio.errors, status: :unprocessable_entity}
      end
    end
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
      params.require(:portfolio).permit(:id,:user_id,:name,:room_type,:style,:wall_color,:portfolio_image)
    end
end



