class Spree::BoardsController < Spree::StoreController
  helper 'spree/taxons'
  helper 'spree/products'
  before_filter :require_authentication, :only => [:new, :design, :preview, :dashboard, :my_profile, :store_credit, :design2]
  before_filter :prep_search_collections, :only => [:index, :search, :edit, :new, :design, :design2]
  before_filter :load_board, :only => [:preview, :design, :destroy, :update, :design2]
  before_filter :require_board_designer, :only => [:dashboard]
  before_filter :get_room_manager, :only => [:submit_for_publication]

  impressionist :actions => [:show]

  def check_generated_board
    hash = {}
    params[:ids].each do  |b|
      board = Spree::Board.find(b)
      if board.generated
        hash[b] = render_to_string '/spree/boards/single_board_check.html.erb', locals: {board: board}, layout: false
      end
    end

    respond_to do |format|
      if hash.present?
        format.json {render json: {boards: hash},status: :ok}
      else
        format.json {render json: {:message => "nothing changed"},status: :unprocessable_entity}
      end
    end
  end

  def add_question
    if params[:board_id].present?
      @question=Spree::Question.new(board_id:params[:board_id],text:params[:text],from:params[:from],send_email:params[:send_email])
      to="(board)"
    elsif params[:product_id].present?
      @question=Spree::Question.new(product_id:params[:product_id],text:params[:text],accepted:true,from:params[:from],send_email:params[:send_email])
      to="(product)"
    end

    respond_to do |format|
      if @question.save
        Resque.enqueue NewQuestionReviewEmail,"support@scoutandnimble.com",'question-review-email',"You have new question",to,params[:text] if Rails.env != "staging"
        format.json {render json: @question, status: :ok}
      else
        format.json {render json: @question.errors, status: :unprocessable_entity}
      end
    end
  end

  def add_answer
    question = Spree::Question.find_by(id:params[:question_id])
    @answer=question.build_answer(text:params[:text])
    respond_to do |format|
      if @answer.save
        Resque.enqueue NewQuestionReviewEmail,"support@scoutandnimble.com",'question-review-email',"New designer answer","",params[:text] if Rails.env != "staging"
        format.json {render json: @answer}
      else
        format.json {render json: @answer.errors}
      end
    end
  end

  def require_board_designer
    if !(spree_current_user and spree_current_user.is_board_designer?)
      if spree_current_user.is_affiliate?
        redirect_to my_profile_path
      else
        redirect_to root_path
      end
    end
  end

  def load_board
    unless @board = spree_current_user.boards.friendly.find(params[:id])
      redirect_to root_path
    end
  end

  def index
    # @boards = Spree::Board.published().order("created_at desc")
    #@products = Spree::Product.featured()
    @colors = Hash.new(0)
    @designers = Hash.new(0)
    @room_type = Hash.new(0)
    @room_style = Hash.new(0)

    tmp_boards = Spree::Board.published().public.order("created_at desc")
    if session[:hash_board_id].present? and session[:remember_product_page].present?
      @jump_to_board_id = session[:hash_board_id]
      @new_next_page = session[:remember_product_page].to_i + 1
      @boards = tmp_boards.page(params[:page]).per(60*session[:remember_product_page].to_i)
      session[:hash_board_id] = nil
      session[:remember_product_page] = nil
    else
      @boards = tmp_boards.page(params[:page]).per(60)
    end

    colors = []
    tmp_boards.each do |b|
      colors += b.color_matches.map { |c| [c.color.color_family,c.color.color_family]}
    end
    room_type = tmp_boards.map { |r| [r.room_type,r.room_type]}
    room_style = tmp_boards.map { |s| [s.room_style,s.room_style]}
    designers = tmp_boards.map {|d| [d.designer.full_name,d.designer.id]}

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
  end

  def room_page
    session[:remember_product_page] = params[:page]
    puts session[:remember_product_page]
    if params[:filter].present?
      tab = []
      params[:filter].except(:color).each do |f|
        tab << "#{f[0]}: #{f[1]}"
      end
      params[:filter][:color].present? ? statement="Spree::Board.active.where(#{tab.join(',').present? ? tab.join(',') : 'nil'}).by_color_family(#{params[:filter][:color]})" : statement="Spree::Board.active.where(#{tab.join(',')})"
      tmp_boards = eval(statement)
      @boards = tmp_boards.page(params[:page]).per(60)
    else
      @boards = Spree::Board.published().order("created_at desc").page(params[:page]).per(60)
    end
    render "room_page", layout: false
  end

  def dashboard
    @projects = Spree::Project.open.where(user_id: spree_current_user.id).order("project_name asc")
    if spree_current_user.designer_registrations.first.status == "room designer"
      @designer_type = "room designer"
      @boards = spree_current_user.boards.where(removal: false)
    elsif spree_current_user.designer_registrations.first.status == "to the trade designer"
      @designer_type = "to the trade designer"
      @boards = spree_current_user.boards.where(removal: false,private: false)
    end
  end

  def profile
    @user = spree_current_user
    if spree_current_user and (spree_current_user.is_beta_user? or spree_current_user.is_designer?)

      @user.user_images.new if @user.user_images.blank?
      @user.marketing_images.new if @user.marketing_images.blank?
      @user.build_logo_image if @user.logo_image.blank?
    else
      redirect_to "/"
    end
  end

  def store_credit
    @user = spree_current_user
  end

  def questions_and_answers
    board_questions = Spree::Question.where("board_id IS NOT NULL").where(accepted:true)
    @questions = []
    board_questions.each do |question|
      board = Spree::Board.find_by(id:question.board_id)
      if board.present?
        if board.designer.id == spree_current_user.id
          @questions << question
        end
      end
    end
  end


  def home
    @boards = Spree::Board.featured().limit(3)
    @board = Spree::Board.featured().order("featured_starts_at desc").first
    lroom, droom, broom = Spree::Taxon.find_by_permalink('rooms/living-room'), Spree::Taxon.find_by_permalink('rooms/dining-room'), Spree::Taxon.find_by_permalink('rooms/bedroom')
    @living_room_boards = Spree::Board.featured().by_room(lroom.id)
    @dining_room_boards = Spree::Board.featured().by_room(droom.id)
    @bedroom_room_boards = Spree::Board.featured().by_room(broom.id)
    @products = Spree::Product.featured()
    #@product = Spree::Product.where("homepage_featured_starts_at <= ? and homepage_featured_ends_at >= ?", Date.today, Date.today).order("homepage_featured_starts_at desc").first

    @selected_section = "home"
    @designers = Spree::User.published_designers().order("created_at desc")

    @slides = Spree::Slide.current.order("created_at desc") || Spree::Slide.defaults


    #@featured_designer = Spree::User.where("designer_featured_starts_at <= ? and designer_featured_ends_at >= ?", Date.today, Date.today).order("designer_featured_starts_at desc").first || Spree::User.published_designers.first
    #@featured_room = @featured_designer.boards.published().featured().last
    #@featured_products = []
    #@featured_products = @featured_room.products.limit(4) if @featured_room
    #puts @designer.inspect
    render :layout => "/spree/layouts/spree_home"
  end

  def search
    @colors = Hash.new(0)
    @designers = Hash.new(0)
    @room_type = Hash.new(0)
    @room_style = Hash.new(0)

    if params[:filter].present?
      tab = []
      params[:filter].except(:color).each do |f|
        tab << "#{f[0]}: #{f[1]}"
      end

      params[:filter][:color].present? ? statement="Spree::Board.active.where(#{tab.join(',').present? ? tab.join(',') : 'nil'}).by_color_family(#{params[:filter][:color]})" : statement="Spree::Board.active.where(#{tab.join(',')})"
      tmp_boards = eval(statement)
      @boards = tmp_boards.page(params[:page]).per(60)

      colors = []
      tmp_boards.each do |b|
        colors += b.color_matches.map { |c| [c.color.color_family,c.color.color_family]}
      end
      room_type = tmp_boards.map { |r| [r.room_type,r.room_type]}
      room_style = tmp_boards.map { |s| [s.room_style,s.room_style]}
      designers = tmp_boards.map {|d| [d.designer.full_name,d.designer.id]}
    else
      tmp_boards = Spree::Board.published().order("created_at desc")
      @boards = tmp_boards.page(params[:page]).per(60)
      colors = []
      tmp_boards.each do |b|
        colors += b.color_matches.map { |c| [c.color.color_family,c.color.color_family]}
      end
      room_type = tmp_boards.map { |r| [r.room_type,r.room_type]}
      room_style = tmp_boards.map { |s| [s.room_style,s.room_style]}
      designers = tmp_boards.map {|d| [d.designer.full_name,d.designer.id]}
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

    render "search",layout: false
  end

  def my_rooms
    @boards = spree_current_user.boards
  end

  def set_out_of_stock_in_room
    @board = Spree::Board.where(slug: params[:slug]).first
    @board.update(show_out_of_stock: params[:value])
    respond_to do |format|
      format.json { head :no_content }
    end
  end

  def show
    @board = Spree::Board.friendly.find(params[:id])
    impressionist(@board)
    session[:hash_board_id] = @board.id
  end

  def show_portfolio
    @portfolio = Spree::Portfolio.find(params[:id])
    @same_room_images = @portfolio.room.portfolios.select{|x| x.id != @portfolio.id}
    @related_rooms = Spree::Portfolio.where("room_type = ? OR style = ? OR wall_color = ?",@portfolio.room_type,@portfolio.style,@portfolio.wall_color).order("RAND()").limit(4)
    # impressionist(@portfolio)
  end

  def preview
    render :action => "show"
  end

  def tear_sheet
    board = Spree::Board.friendly.find(params[:id])
    project = board.project
    user = board.designer
    designer = user.designer_registrations.first
    board_products = board.board_products#.map{|x| x.product.present? ? x.product : x.custom_item}
    subtotal = Spree::BoardProduct.calculate_subtotal(board_products,true)
    total = Spree::BoardProduct.calculate_subtotal(board_products,true)

    taxcloud=board.calculate_tax

    respond_to do |format|
      format.pdf do
        render pdf: "tear_sheet", locals: {designer: designer, user: user, board: board, board_products: board_products,subtotal: subtotal, tax: taxcloud, total: total, project: project}, orientation: 'Landscape'
      end
      format.html{ render html: "tear_sheet",locals: {designer: designer, user: user, board: board, board_products: board_products,subtotal: subtotal, tax: taxcloud, total: total, project: project}, layout: false }
    end
  end

  def edit
    @board = Spree::Board.find(params[:id])
    @colors = Spree::Color.order(:position).where("position > 144 and position < 1000")
    num_colors = @board.colors.size + 1
    num_colors.upto(5) do |n|
      @board.colors.build
    end
  end

  def new
    date = DateTime.now
    if spree_current_user.boards.where("created_at BETWEEN ? AND ?",date.beginning_of_month,date.end_of_month).count < Spree::Config[:room_creation_limit]
      project_id = nil || params[:project_id]
      @board = Spree::Board.new(:name => "Untitled Room",private: params[:private],project_id: project_id)
      @board.designer = spree_current_user
      if @board.save!
        Spree::BoardHistory.create(user_id: @board.designer.id, board_id: @board.id, action: "room_create")
        redirect_to design_board_path(@board)
      end
    else
      flash[:notice] = "You have reached maximum amount of created rooms for current month"
      redirect_to designer_dashboard_path
    end

    #@colors = Spree::Color.order(:position).where("position > 144 and position < 1000")

    #1.upto(5) do |n|
    #  @board.colors.build
    #end
  end

  def reload_filters
    @board = Spree::Board.where(id: params[:board_id]).first
    @my_taxon = Spree::Taxon.where(id: params[:room_id]).first
    @searcher = build_searcher(params)
    #@taxon_filters = Spree::Product.generate_new_filters(@my_taxon)
    @searcher.retrieve_products({where: "supplier_id = #{@my_taxon.id}"})
    respond_to do |format|
      format.html { render :layout => false }
    end

  end

  def product_result
    params.merge(:per_page => 60)

    @board = Spree::Board.where(id: params[:board_id]).first

    if @board.present? and @board.show_out_of_stock == true
      out_of_stock = {order: "quantity_on_hand DESC, spree_variants.backorderable DESC"}
    else
      out_of_stock = {where: "quantity_on_hand > 0 "}
    end
    taxons = []
    unless taxons.empty?
      @searcher = build_searcher(params.merge(:taxon => taxons))
    else
      @searcher = build_searcher(params)
    end
    if params[:supplier_id] and params[:supplier_id].to_i > 0
      @all_products = @searcher.retrieve_products({where: "supplier_id = #{params[:supplier_id]}"}, out_of_stock,  {page: params[:page] || 1, per_page: params[:per_page] || 60})
    else
      @all_products = @searcher.retrieve_products(out_of_stock,  {page: params[:page] || 1, per_page: params[:per_page] || 60})
    end
    @products = @all_products

    @sign_in_count = spree_current_user.sign_in_count

    session[:t_filter]=1 if @products.present?
    respond_to do |format|
      format.html { render :layout => false }
    end
  end

  def product_result_page
    params.merge(:per_page => 60)

    @board = Spree::Board.where(id: params[:board_id]).first

    if @board.present? and @board.show_out_of_stock == true
      out_of_stock = {order: "quantity_on_hand DESC, spree_variants.backorderable DESC"}
    else
      out_of_stock = {where: "quantity_on_hand > 0 "}
    end
    taxons = []
    unless taxons.empty?
      @searcher = build_searcher(params.merge(:taxon => taxons))
    else
      @searcher = build_searcher(params)
    end
    if params[:supplier_id] and params[:supplier_id].to_i > 0
      @all_products = @searcher.retrieve_products({where: "supplier_id = #{params[:supplier_id]}"}, out_of_stock,  {page: params[:page] || 1, per_page: params[:per_page] || 60})
    else
      @all_products = @searcher.retrieve_products(out_of_stock,  {page: params[:page] || 1, per_page: params[:per_page] || 60})
    end
    @products = @all_products

    @sign_in_count = spree_current_user.sign_in_count

    session[:t_filter]=1 if @products.present?
    respond_to do |format|
      format.html { render :layout => false }
    end
  end

  def product_search
    Spree::SearchKey.create(key: params[:keywords].strip, user_id: spree_current_user.id) if params[:keywords].present? and spree_current_user.present?
    params.merge(:per_page => 100)
    if params[:s].present?
      w = params[:s].each do |key, val|
        if val.class != [].class
          val = YAML.load(val)
          params[:s][key.to_sym] = val
        end
      end
      params[:s] = w
    end
    #if params[:supplier_id]
    #  params.merge(:supplier_id => params[:supplier_id])
    #end
    taxons = []
    #unless params[:wholesaler_taxon_id].blank?
    #  taxon = Spree::Taxon.find(params[:wholesaler_taxon_id])
    #  taxons << taxon.id
    #end

    #if params[:id] and !params[:id].empty?
    #  taxon = Spree::Taxon.find(params[:department_taxon_id])
    #  taxons << taxon.id
    #end
    @my_taxon = Spree::Taxon.where(id: params[:id]).first
    #@taxon_filters = Spree::Product.generate_new_filters(@my_taxon)


    unless taxons.empty?
      @searcher = build_searcher(params.merge(:taxon => taxons))
    else
      @searcher = build_searcher(params)
    end

    @board = Spree::Board.find(params[:board_id])

    if @board.private
      if params[:supplier_id] and params[:supplier_id].to_i > 0
        # @all_products = @searcher.retrieve_products.by_supplier(params[:supplier_id]).not_on_a_board
        #@all_products =  @searcher.retrieve_products({where: "supplier_id = #{params[:supplier_id]}"}, {includes: :board_products}, {where: "spree_board_products.product_id is NULL"})
        @all_products = @searcher.retrieve_products({where: "supplier_id = #{params[:supplier_id]}"}, {order: "quantity_on_hand DESC, spree_variants.backorderable DESC"})
      else
        # @all_products = @searcher.retrieve_products.not_on_a_board
        #@all_products = @searcher.retrieve_products( {includes: :board_products}, {where: "spree_board_products.product_id is NULL"})
        @all_products = @searcher.retrieve_products({order: "quantity_on_hand DESC, spree_variants.backorderable DESC"})
      end
    else
      if params[:supplier_id] and params[:supplier_id].to_i > 0
        # @all_products = @searcher.retrieve_products.by_supplier(params[:supplier_id]).not_on_a_board
        #@all_products =  @searcher.retrieve_products({where: "supplier_id = #{params[:supplier_id]}"}, {includes: :board_products}, {where: "spree_board_products.product_id is NULL"})
        @all_products = @searcher.retrieve_products({where: "supplier_id = #{params[:supplier_id]}"}, {where: "available_sans_board = ture"}, {order: "quantity_on_hand DESC, spree_variants.backorderable DESC"})
      else
        # @all_products = @searcher.retrieve_products.not_on_a_board
        #@all_products = @searcher.retrieve_products( {includes: :board_products}, {where: "spree_board_products.product_id is NULL"})
        @all_products = @searcher.retrieve_products({where: "available_sans_board = true"}, {order: "quantity_on_hand DESC, spree_variants.backorderable DESC"})
      end
    end
    @products = @all_products

    #@products = @all_products.select { |product| product.not_on_a_board? }
    #if params[:supplier_id]
    #  @products = @all_products.by_supplier(params[:supplier_id])
    #else
    #  @products = @all_products.by_supplier(supplier_id)
    #end

    @board = Spree::Board.find(params[:board_id])

    #@products = Spree::Product.all()
    respond_to do |format|
      format.js { render :layout => false }
      #format.html { redirect_to([:admin, @booking], :notice => 'Booking was successfully created.') }
      #format.xml  { render :xml => @booking, :status => :created, :location => @booking }
    end
  end

  def create
    @board = Spree::Board.new(board_params)
    @board.designer = spree_current_user
    if @board.save
      respond_to do |format|
        format.html {redirect_to build_board_path(@board)}
        format.json { render json: {location: build_board_path(@board)}}
        format.js { render json: {location: build_board_path(@board)}}
      end
    else
    end
  end

  def update
    puts '****'
    puts params.inspect
    puts '****'
    session[:page_count]=0
    @board.slug = nil
    @board.update_column(:generated,false)
    #respond_to do |format|
    @board.create_or_update_board_product(params,@board.id,@board.not_published_email)
    @board.update_column(:not_published_email,true)
    if @board.update_attributes(board_params)
      time_spent=DateTime.now.to_time-@board.time_start.to_time
      current_spent=@board.time_spent
      @board.update_column(:time_spent, time_spent+current_spent)

      spree_current_user.update_column(:popup_room, false)

      if params[:is_assigned_to_portfolio].present?
        Spree::Portfolio.where(board_id: @board.id).update_all(board_id: nil)
        portfolio = Spree::Portfolio.find(params[:is_assigned_to_portfolio])
        @board.private ? portfolio.update(board_id: @board.id) : portfolio.update(board_id: @board.id,room_type: params[:board][:room_id],style: params[:board][:style_id])
        portfolio.room.portfolios.where.not(id: params[:is_assigned_to_portfolio]).update_all(board_id: @board.id, updated_at: DateTime.now+20.seconds)
      else
        Spree::Portfolio.where(board_id: @board.id).update_all(board_id: nil)
      end

      @board.submit_for_publication! if params[:board][:status] == "submitted_for_publication"
      # @board.queue_image_generation
      @board.designer.update(tutorial_roombuilder: true)
      respond_to do |format|
        format.html {redirect_to designer_dashboard_path(@board, :notice => 'Your board was updated.', private: @board.private, id: @board.project.present? ? @board.project.id : '')}
        format.json { render json: {location: designer_dashboard_path(@board, :notice => 'Your board was updated.', private: @board.private, id: @board.project.present? ? @board.project.id : '')}}
        format.js { render json: {location: designer_dashboard_path(@board, :notice => 'Your board was updated.', private: @board.private, id: @board.project.present? ? @board.project.id : '')}}
      end
    else
      puts @board.errors.collect { |e| e.to_s }
      #format.html { render :action => "design"}
    end
    #end
  end

  def submit_for_publication

    @board = Spree::Board.find_by slug: params[:id]
    @board.set_state_transition_context(params[:board][:state_message], spree_current_user)
    @board.submit_for_publication
    html_content = "There is a new room for you to review."
    html_content << "<br /><br />Message from Designer:<br /><br />#{params[:board][:state_message]}" if params[:board] and params[:board][:state_message] and !params[:board][:state_message].blank?

    @board.designer.send_message(@room_manager, "Room Submitted by #{@board.designer.full_name}", html_content, true, nil, Time.now, @board)
    session[:page_count]=1
    redirect_to designer_dashboard_path
  end

  def build
    @board = Spree::Board.find(params[:id])
    @products = Spree::Product.all()
    @department_taxons = Spree::Taxonomy.where(:name => 'Department').first().root.children
    @wholesaler_taxons = Spree::Taxonomy.where(:name => 'Wholesaler').first().root.children
  end

  def gettaxons

    @searcher = build_searcher(params.merge(:supplier_id => params[:supplier_id], :per_page => 5000))
    @supplierid = params[:supplier_id]
    if params[:supplier_id].present?
      @all_products = @searcher.retrieve_products.by_supplier(params[:supplier_id])
    else
      @all_products = @searcher.retrieve_products
    end

    department_taxons = Spree::Taxonomy.where(:name => 'Department').first().root.children
    product_taxon_ids = @all_products.collect { |p| p.taxons.collect { |t| t.id } }.flatten.uniq
    @ary = department_taxons.where(:id => product_taxon_ids).map { |taxon| [taxon.name, taxon.id] }

    #@ary = Array.new(Array.new) 
    #
    #
    #
    #@all_products.each do |prod|
    #  @prod = Spree::Product.find_by_id(prod.id)
    #  @prod.taxons.each do |tax|
    #    @ary.push([tax.name,tax.id])
    #  end
    #end
    render :json => @ary
  end

  def design
    @board.update_column(:time_start, DateTime.now)
    @portfolios = spree_current_user.portfolios
    @portfolio_id = @board.portfolios.order(:updated_at).first.id if @board.portfolios.present?
    @portfolios = spree_current_user.portfolios.select{|x| !x.board_id.present?}
    # @portfolios << @board.portfolios.first if @board.portfolios.present?
    @board.portfolios.map{|x| @portfolios << x}

    @category = []
    @subcategory = []
    @sub_subcategory = []
    @category_id = ""
    @subcategory_id = ""
    @sub_subcategory_id = ""
    @supplier = Spree::Supplier.new
    @my_taxon = Spree::Taxon.where(name: 'Department').first
    @my_taxon.children.each do |taxon|
      @category << [taxon.name, taxon.id]
    end

    #@board.messages.new(:sender_id => spree_current_user.id, :recipient_id => 0, :subject => "Publication Submission")
    @products = Spree::Product.all()
    @bookmarked_products = spree_current_user.bookmarks.collect { |bookmark| bookmark.product }
    @department_taxons = Spree::Taxonomy.where(:name => 'Department').first().root.children

    #@department_taxons= Spree::Supplier.find_by(id: 16).taxons 
    @searcher = build_searcher(params)

    @all_products = @searcher.retrieve_products.by_supplier('')
    @ary = Array.new(Array.new)

    @all_products.each do |prod|
      @prod = Spree::Product.find_by_id(prod.id)

      @prod.taxons.each do |tax|
        @ary.push([tax.name, tax.id])
      end
    end

    #@wholesaler_taxons = Spree::Taxonomy.where(:name => 'Wholesaler').first().root.children

    @color_collections = Spree::ColorCollection.all()
  end

  def search_all_categories
    @subcategory = []
    @sub_subcategory = []
    @category = []
    @suppliers = []
    @board = Spree::Board.where(id: params[:board_id]).first
    if params[:supplier_id].present?
      @supplier = Spree::Supplier.where(id: params[:supplier_id]).first
    else
      @supplier = Spree::Supplier.new
    end
    tab = []

    if params[:keywords].present?
      @searcher = build_searcher(params)
      @searcher.retrieve_products
      tab = @searcher.solr_search.facet(:brand_name).rows.map(&:value)
      if params[:type].blank? and params[:id].blank?
        params[:type] = 'categories'
        params[:id] = Spree::Taxon.where(permalink: tab.first).first.id
        @room_id = params[:id]
      end
    end

    @category_find = Spree::Taxonomy.where(:name => 'Department').first.root.children
    @category_find.map do |tax|
      if tab.present?
        # if tab.include?(tax.name)
          @category << [tax.name, tax.id]
        # end
      else
        @category << [tax.name, tax.id]
      end
    end


    if params[:type].to_s == "categories"
      @category_id = Spree::Taxon.where(id: params[:id]).first
      params[:s] = {} if params[:s].blank?
      params[:s][:brand_name] = @category_id.permalink
      @searcher = build_searcher(params)
      @searcher.retrieve_products
      @suppliers = Spree::Board.generate_brands(@searcher)
      @category_id.children.each do |taxon|
        if tab.present?
          if tab.include?(taxon.permalink)
            @subcategory << [taxon.name, taxon.id]
          end
        else
          @subcategory << [taxon.name, taxon.id]
        end
      end
      #@taxon_filters = Spree::Product.generate_new_filters(@category_id)
    elsif params[:type].to_s == "subcategories"
      @subcategory_id = Spree::Taxon.where(id: params[:id]).first
      params[:s] = {} if params[:s].blank?
      params[:s][:brand_name] = @subcategory_id.permalink
      @searcher = build_searcher(params)
      @searcher.retrieve_products
      @suppliers = Spree::Board.generate_brands(@searcher)
      @category_id = Spree::Taxon.where(id: @subcategory_id.parent.id).first

      @category_id.children.each do |taxon|
        if tab.present?
          if tab.include?(taxon.name)
            @subcategory << [taxon.name, taxon.id]
          end
        else
          @subcategory << [taxon.name, taxon.id]
        end
      end

      @subcategory_id.children.each do |taxon|
        if tab.present?
          if tab.include?(taxon.permalink)
            @sub_subcategory << [taxon.name, taxon.id]
          end
        else
          @sub_subcategory << [taxon.name, taxon.id]
        end
      end
      #@taxon_filters = Spree::Product.generate_new_filters(@subcategory_id)
    elsif params[:type].to_s == "sub_subcategories"
      @sub_subcategory_id = Spree::Taxon.where(id: params[:id]).first
      params[:s] = {} if params[:s].blank?
      params[:s][:brand_name] = @sub_subcategory_id.permalink
      @searcher = build_searcher(params)
      @searcher.retrieve_products
      @suppliers = Spree::Board.generate_brands(@searcher)
      @subcategory_id = Spree::Taxon.where(id: @sub_subcategory_id.parent.id).first
      @category_id = Spree::Taxon.where(id: @subcategory_id.parent.id).first
      @category_id.children.each do |taxon|
        if tab.present?
          if tab.include?(taxon.permalink)
            @subcategory << [taxon.name, taxon.id]
          end
        else
          @subcategory << [taxon.name, taxon.id]
        end
      end
      @subcategory_id.children.each do |taxon|
        if tab.present?
          if tab.include?(taxon.name)
            @sub_subcategory << [taxon.name, taxon.id]
          end
        else
          @sub_subcategory << [taxon.name, taxon.id]
        end
      end
      #@taxon_filters = Spree::Product.generate_new_filters(@sub_subcategory_id)
    end

    respond_to do |format|
      format.html { render layout: false }
    end
  end

  def design2

    #@board.messages.new(:sender_id => spree_current_user.id, :recipient_id => 0, :subject => "Publication Submission")
    @products = Spree::Product.all()
    @bookmarked_products = spree_current_user.bookmarks.collect { |bookmark| bookmark.product }
    @department_taxons = Spree::Taxonomy.where(:name => 'Department').first().root.children
    #@department_taxons= Spree::Supplier.find_by(id: 16).taxons 
    @searcher = build_searcher(params)

    @all_products = @searcher.retrieve_products.by_supplier('')
    @ary = Array.new(Array.new)

    @all_products.each do |prod|
      @prod = Spree::Product.find_by_id(prod.id)

      @prod.taxons.each do |tax|
        @ary.push([tax.name, tax.id])
      end
    end

    @suppliers = Spree::Supplier.where(:public => 1).order(:name)
    #@wholesaler_taxons = Spree::Taxonomy.where(:name => 'Wholesaler').first().root.children

    @color_collections = Spree::ColorCollection.all()
  end

  def destroy
    if @board
      @board.update(removal: true)
      Resque.enqueue DeleteRoom,@board.id
      flash[:notice] = "The room has been deleted."
    else
      flash[:warning] = "We could not delete this room."
    end
    respond_to do |format|
      format.html { redirect_to designer_dashboard_path }
      format.json { render json: {message: "success"}, status: :ok }
    end

  end

  def add_board_favorite
    board = Spree::BoardFavorite.new(user_id: params[:user_id],board_id: params[:board_id])
    respond_to do |format|
      if board.save
        format.json {render json: {}, status: :ok}
      else
        format.json {render json: board.errors, status: :unprocessable_entity}
      end
    end
  end

  def remove_board_favorite
    board = Spree::BoardFavorite.find_by(user_id: params[:user_id],board_id: params[:board_id])
    respond_to do |format|
      if board.destroy
        format.json {render json: {}, status: :ok}
      else
        format.json {render json: board.errors, status: :unprocessable_entity}
      end
    end
  end

  def make_public
    board = Spree::Board.find_by_slug(params[:id])
    respond_to do |format|
      if board.board_products.where.not(custom_item_id: nil).empty?
        board.update_columns(private: false,project_id: nil, time_spent: nil, time_start: nil)
        board.touch
        actions = render_to_string(partial: "/spree/boards/board_actions_public.html.erb", locals: {board: board}, formats: ['html'])
        columns = render_to_string(partial: "/spree/boards/board_public_columns.html.erb", locals: {board: board}, formats: ['html'])
        format.json {render json: {message: "Board set as public", actions: actions, columns: columns}, status: :ok}
      else
        format.json {render json: {message: "Remove custom products from this room"}, status: :unprocessable_entity}
      end
    end
  end

  private
  def prep_search_collections
    @room_taxons = Spree::Taxonomy.where(:name => 'Rooms').first().root.children.select { |child| Spree::Board.available_room_taxons.include?(child.name) }
    @style_taxons = Spree::Taxonomy.where(:name => 'Styles').first().root.children
    @colors = Spree::Color.order(:position)
    @designers = Spree::User.published_designers().order("created_at desc")
  end

  def board_params
    params.require(:board).permit(:name, :description, :style_id, :room_id, :status, :message, :featured, :featured_starts_at, :featured_expires_at, :board_commission, :featured_copy, :featured_headline, :project_id)#:customer_address, :customer_zipcode, :state_id, :customer_city
  end
  # redirect to the edit action after create
  #create.response do |wants|
  #  show.html { redirect_to edit_admin_fancy_thing_url( @fancy_thing ) }
  #end
  #
  ## redirect to the edit action after update
  #update.response do |wants|
  #  wants.html { redirect_to edit_admin_fancy_thing_url( @fancy_thing ) }
  #end

end



