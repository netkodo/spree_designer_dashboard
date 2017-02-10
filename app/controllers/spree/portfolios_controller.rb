class Spree::PortfoliosController < Spree::StoreController

  def index
    @colors = Hash.new(0)
    @designers = Hash.new(0)
    @room_type = Hash.new(0)
    @room_style = Hash.new(0)
    @tags = Hash.new(0)

    tmp_portfolios = Spree::Portfolio.all.order('board_id IS NULL, created_at DESC')
    @portfolios = tmp_portfolios.page(params[:page]).per(60)
    # params[:cols].to_i > 768 ? @portfolios_ordering = Spree::Portfolio.portfolios_ordering(@portfolios,3) : @portfolios_ordering = Spree::Portfolio.portfolios_ordering(@portfolios,2)
    # colors = tmp_portfolios.map { |c| [c.wall_color,c.wall_color]}
    colors = []
    tmp_portfolios.each do |wc|
      # colors << [wc.wall_color,wc.wall_color]
      if wc.board.present? and wc.board.colors.present?
        wc.board.colors.each do |c|
          colors << [c.color_family,c.color_family]
        end
      else
        colors << [wc.wall_color,wc.wall_color]
      end
    end
    room_type = tmp_portfolios.map { |r| [r.room_types.name,r.room_types.id]}
    room_style = tmp_portfolios.map { |s| [s.room_styles.name,s.room_styles.id]}
    designers = tmp_portfolios.map {|d| [d.user.full_name,d.user.id]}
    tags = Spree::Portfolio.get_filter_tags(tmp_portfolios)

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

    tags.each do |v|
      @tags[v] +=1
    end
  end

  def portfolio_page
    if params[:filter].present?
      tab = []
      params[:filter].except('tags','wall_color').each do |f|
        tab << "#{f[0]}: #{f[1]}"
      end

      params[:filter][:wall_color].present? ? wall_s = ".includes(:board => :colors).where(\"wall_color IN (?) OR spree_colors.name IN (?)\",#{params[:filter][:wall_color]},#{params[:filter][:wall_color]})" : nil
      params[:filter][:tags].present? ? tag_s = ".select{|s| s.check_tags(#{params[:filter][:tags]})}" : nil
      tab.join(',').present? ? statement = "Spree::Portfolio#{wall_s}.where(#{tab.join(',')})#{tag_s}" : statement = "Spree::Portfolio#{wall_s}#{tag_s}"

      tmp_portfolios = eval(statement).order('spree_portfolios.board_id IS NULL, spree_portfolios.created_at DESC')#,board_id DESC
      if params[:page].present? and params[:page].to_i > 1
        @obj = []
        (1..params[:page].to_i).each do |page|
          tmp_portfolios.page(page).per(60).each do |portfolio|
            @obj << portfolio
          end
        end
      end

      @portfolios = Kaminari.paginate_array(tmp_portfolios).page(params[:page]).per(60)
      # params[:cols].to_i > 768 ? @portfolios_ordering = Spree::Portfolio.portfolios_ordering(obj,3) : @portfolios_ordering = Spree::Portfolio.portfolios_ordering(obj,2)
    else
      tmp_portfolios = Spree::Portfolio.all.order('spree_portfolios.board_id IS NULL, spree_portfolios.created_at DESC')
      if params[:page].present? and params[:page].to_i > 1
        @obj = []
        (1..params[:page].to_i).each do |page|
          tmp_portfolios.page(page).per(60).each do |portfolio|
            @obj << portfolio
          end
        end
      end
      # tmp_portfolios = Spree::Portfolio.all.order('created_at DESC')
      @portfolios = Kaminari.paginate_array(tmp_portfolios).page(params[:page]).per(60)
      # params[:cols].to_i > 768 ? @portfolios_ordering = Spree::Portfolio.portfolios_ordering(obj,3) : @portfolios_ordering = Spree::Portfolio.portfolios_ordering(obj,2)
    end
    render "portfolio_page", layout: false
  end

  def search
    @colors = Hash.new(0)
    @designers = Hash.new(0)
    @room_type = Hash.new(0)
    @room_style = Hash.new(0)
    @tags = Hash.new(0)

    if params[:filter].present?
      tab = []
      params[:filter].except('tags','wall_color').each do |f|
        tab << "#{f[0]}: #{f[1]}"
      end

      params[:filter][:wall_color].present? ? wall_s = ".includes(:board => :colors).where(\"wall_color IN (?) OR spree_colors.color_family IN (?)\",#{params[:filter][:wall_color]},#{params[:filter][:wall_color]})" : nil
      params[:filter][:tags].present? ? tag_s = ".select{|s| s.check_tags(#{params[:filter][:tags]})}" : nil
      tab.join(',').present? ? statement = "Spree::Portfolio#{wall_s}.where(#{tab.join(',')})#{tag_s}" : statement = "Spree::Portfolio#{wall_s}#{tag_s}"

      tmp_portfolios = eval(statement)#.order('spree_portfolios.board_id IS NULL, spree_portfolios.created_at DESC')
      @portfolios = Kaminari.paginate_array(tmp_portfolios).page(params[:page]).per(60)
      # params[:cols].to_i > 768 ? @portfolios_ordering = Spree::Portfolio.portfolios_ordering(@portfolios,3) : @portfolios_ordering = Spree::Portfolio.portfolios_ordering(@portfolios,2)
      # colors = tmp_portfolios.map { |c| [c.wall_color,c.wall_color]}
      colors = []
      tmp_portfolios.each do |wc|
        # colors << [wc.wall_color,wc.wall_color]
        if wc.board.present? and wc.board.colors.present?
          wc.board.colors.each do |c|
            colors << [c.color_family,c.color_family]
          end
        else
          colors << [wc.wall_color,wc.wall_color]
        end
      end
      room_type = tmp_portfolios.map { |r| [r.room_types.name,r.room_types.id]}
      room_style = tmp_portfolios.map { |s| [s.room_styles.name,s.room_styles.id]}
      designers = tmp_portfolios.map {|d| [d.user.full_name,d.user.id]}
      tags = Spree::Portfolio.get_filter_tags(tmp_portfolios)
    else
      tmp_portfolios = Spree::Portfolio.all.order('board_id IS NULL, created_at DESC')
      @portfolios = tmp_portfolios.page(params[:page]).per(60)
      # params[:cols].to_i > 768 ? @portfolios_ordering = Spree::Portfolio.portfolios_ordering(@portfolios,3) : @portfolios_ordering = Spree::Portfolio.portfolios_ordering(@portfolios,2)
      # colors = tmp_portfolios.map { |c| [c.wall_color,c.wall_color]}
      colors = []
      tmp_portfolios.each do |wc|
        # colors << [wc.wall_color,wc.wall_color]
        if wc.board.present? and wc.board.colors.present?
          wc.board.colors.each do |c|
            colors << [c.color_family,c.color_family]
          end
        else
          colors << [wc.wall_color,wc.wall_color]
        end
      end
      room_type = tmp_portfolios.map { |r| [r.room_types.name,r.room_types.id]}
      room_style = tmp_portfolios.map { |s| [s.room_styles.name,s.room_styles.id]}
      designers = tmp_portfolios.map {|d| [d.user.full_name,d.user.id]}
      tags = Spree::Portfolio.get_filter_tags(tmp_portfolios)
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

    tags.each do |v|
      @tags[v] +=1
    end

    render "spree/portfolios/search",layout: false
  end

  def get_tags
    hash = {}
    Spree::Tag.where("tag LIKE ?","#{params[:s]}%").each_with_index.map{|s,i| hash[i]=s.tag}

    respond_to do |format|
      if hash.length >= 1
        format.json {render json: hash,status: :ok}
      else
        format.json {render json: {message: "nothing found"},status: :unprocessable_entity}
      end
    end
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

  def destroy_portfolio
    @portfolio = Spree::Portfolio.find(params[:id])
    respond_to do |format|
      if @portfolio.destroy
        format.json {render json: @portfolio, status: :ok}
      else
        format.json {render json: @portfolio.errors, status: :unprocessable_entity}
      end
    end
  end

  def new_portfolio
    @colors = Spree::Board.color_categories
    rooms = Spree::Taxonomy.where(:name => 'Rooms').first().root.children.select { |child| Spree::Board.available_room_taxons.include?(child.name) }
    styles = Spree::Taxonomy.where(:name => 'Styles').first().root.children
    @room_type = rooms.map {|r| [r.name,r.id]}
    @room_style = styles.map {|s| [s.name,s.id]}

    @portfolio = Spree::Portfolio.new
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

    if x[:tags].present? and params[:portfolio][:tags] != @portfolio.tags
      x[:tags].split(',').each do |t|
        unless Spree::Tag.find_by(tag: t).present?
          Spree::Tag.create(tag: t)
        end
      end
    end

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

    if x[:room_id].present?
      room_id = x[:room_id]
    else
      room_id = Spree::Room.create(user_id: spree_current_user.id).id
      x[:room_id] = room_id
    end

    if x[:tags].present?
      x[:tags].split(',').each do |t|
        unless Spree::Tag.find_by(tag: t).present?
          Spree::Tag.create(tag: t)
        end
      end
    end

    @portfolio = Spree::Portfolio.new(x)

    respond_to do |format|
      if @portfolio.save
        spree_current_user.user_ac_event_add("first_portfolio_added") if spree_current_user.active_campaign.blank? || !spree_current_user.active_campaign.first_portfolio_added
        format.html {redirect_to portfolio_path}
        format.json {render json: @portfolio, status: :ok}
      else
        format.html {redirect_to portfolio_path}
        format.json {render json: @portfolio.errors, status: :unprocessable_entity}
      end
    end
  end

  def single_portfolio_edit
    @portfolio=Spree::Portfolio.find(params[:id])

    respond_to do |format|
      if @portfolio.present?
        format.html {render partial: 'portfolio_item_edit', locals: {p: @portfolio,cols: 3}}
      else
        format.html {redirect_to portfolio_path}
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
      params.require(:portfolio).permit(:id,:user_id,:name,:room_type,:style,:wall_color,:portfolio_image,:description,:paint_brand,:paint_name,:tags,:room_id)
    end
end
