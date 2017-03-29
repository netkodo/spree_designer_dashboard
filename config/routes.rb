Spree::Core::Engine.routes.draw do
  # Add your extension routes here

  # auto-login links
  get '/al/:id' => 'users#auto_login', :as => :auto_login

  match "/rooms/product_search" => "boards#product_search", :as => :board_product_search, :via =>[:post]
  post "/rooms/search" => "boards#search", :as => :board_search,:defaults => {:format => 'html'}
  post "/room_page" => "boards#room_page", :as => :room_page,:defaults => {:format => 'html'}
  get "/rooms/gettaxons" => "boards#gettaxons", :as => :board_gettaxons
  get "/portfolios/:id" => "boards#show_portfolio", :as => :show_portfolio

  resources :board_products
  resources :color_collections do
    resources :colors
  end
  resources :rooms, controller: 'boards'  do

    collection do
      post :search_all_categories
      post :product_result
      post :product_result_page, :defaults => {:format => 'html'}
      post :reload_filters
      post :set_out_of_stock_in_room
    end
    resources :board_products
    resources :color_matches
  end
  resources :designer_registrations




  get "/tutorials" => "designers#tutorials", :as => :tutorials
  get "/designers" => "designers#index", :as => :designers
  get "/designers/thanks" => "designer_registrations#thanks", :as => :designer_registration_thanks
  get "/designers/signup" => "designer_registrations#new", :as => :designer_signup
  patch "/designers" => "designers#update", :as => :update_designer
  #post "/designers/signup" => "designers#signup", :as => :create_designer_registration

  #portfolio routes
  post "/portfolio_content" => "portfolios#portfolio_content", :as => :portfolio_content
  get "/portfolio" => "portfolios#portfolio", as: :portfolio
  get "/new_portfolio" => "portfolios#new_portfolio", as: :new_portfolio
  get "/edit_portfolio" => "portfolios#edit_portfolio", as: :edit_portfolio
  post "/update_portfolio" => "portfolios#update_portfolio", :as => :update_portfolio, :defaults => {:format => 'json'}
  delete "/destroy_portfolio" => "portfolios#destroy_portfolio", :as => :destroy_portfolio, :defaults => {:format => 'json'}
  post "/portfolio" => "portfolios#create_portfolio", as: :create_portfolio,:defaults => {:format => 'json'}
  get "/portfolios" => "portfolios#index", as: :index
  post "/portfolios_search" => "portfolios#search", as: :portfolios_search, :defaults => {:format => 'html'}
  post "/portfolio_page" => "portfolios#portfolio_page", :as => :portfolio_page
  post "/single_portfolio_edit" => "portfolios#single_portfolio_edit", :as => :single_portfolio_edit, :defaults => {:format => 'html'}

  post "/get_tags" => "portfolios#get_tags", :as => :get_tags, :defaults => {:format => 'json'}

  #project routes
  resources :projects do
    member do
      post :close_open, defaults: {format: 'json'}
      # get :contract
      resources :contracts, param: :cid
    end
  end
  # match 'projects/:pid/contracts/:cid' => "contracts#show"
  get "/sign_contract/:token" => "contracts#preview_sign_contract", :as => :preview_sign_contract
  patch "/sign_contract/:token/sign" => "contracts#sign_contract", :as => :sign_contract

  #favoretes portfolio & board
  post "/check_generated_board" => "boards#check_generated_board", :as => :check_generated_board, :defaults => {:format => 'json'}

  post "/add_portfolio_favorite" => "portfolios#add_portfolio_favorite", :as => :add_portfolio_favorite,:defaults => {:format => 'json'}
  delete "/remove_portfolio_favorite" => "portfolios#remove_portfolio_favorite", :as => :remove_portfolio_favorite,:defaults => {:format => 'json'}

  post "/add_board_favorite" => "boards#add_board_favorite", :as => :add_board_favorite,:defaults => {:format => 'json'}
  delete "/remove_board_favorite" => "boards#remove_board_favorite", :as => :remove_board_favorite,:defaults => {:format => 'json'}

  get "/mission" => "extra#mission" , :as => :mission
  get "/share-to-earn" => "extra#share_to_earn" , :as => :share_to_earn
  get "/home2" => "boards#home", :as => :home2
  get "/home" => "home#home2", :as => :home
  post "/orders/add_to_cart" => "orders#add_to_cart", :as => :orders_add_to_cart

  #review
  get "/review/:token" => 'home#user_review', as: :user_product_review_new,:defaults => {:format => 'html'}
  post "/review/:token/create" => 'home#create_user_review', as: :user_product_review_create,:defaults => {:format => 'json'}

  # designer dashboard links
  get "/dashboard" => "boards#dashboard", :as => :designer_dashboard
  get "/my_profile" => "boards#profile", :as => :my_profile
  get "/my_store_credit" => "boards#store_credit", :as => :my_store_credit
  get "/questions_and_answers" => "boards#questions_and_answers", :as => :questions_and_answers
  get "/my_rooms" => "boards#my_rooms", :as => :my_rooms
  resources :bookmarks, except: [:index]
  get "/favorites_products" => "bookmarks#index"
  get "/favorites" => "bookmarks#favorites"
  post "/board_favorites" => "bookmarks#board_favorites"
  post "/portfolio_favorites" => "bookmarks#portfolio_favorites"
  post "/product_favorites" => "bookmarks#product_favorites"

  post "/bookmarks/remove" => "bookmarks#destroy", :as => :remove_bookmark
  get "/our_suppliers" => "extra#our_suppliers", :as => :our_suppliers
  get "/tips_tricks" => "extra#tips_tricks", :tips_tricks => :tips_tricks
  get "/video_tutorial" => "extra#video_tutorial", :as => :video_tutorial

  post "/create_color_match" => "color_matches#create_color_match", as: :create_color_match, :defaults => {:format => 'json'}

  post "/private_invoice" => "invoice_lines#private_invoice", as: :private_invoice, :defaults => {:format => 'html'}
  post "/send_invoice_email" => "invoice_lines#send_invoice_email", as: :send_invoice_email, :defaults => {:format => 'json'}
  get "/show_invoice_email" => "invoice_lines#show_invoice_email", as: :show_invoice_email, :defaults => {:format => 'html'}
  post "/save_invoice" => "invoice_lines#save_invoice", as: :save_invoice, :defaults => {:format => 'json'}

  post "/send_contract/:id" => "contracts#send_contract", as: :send_contract, :defaults => {:format => 'json'}
  get "/show_contract/:id" => "contracts#show_contract", as: :show_contract, :defaults => {:format => 'html'}

  post "/board_history" => "board_history#board_history", as: :board_history, :defaults => {:format => 'html'}
  post "/create_board_history" => "board_history#create", as: :create_board_history, :defaults => {:format => 'json'}

  # room builder links
  post '/rooms/add_question' => "boards#add_question"
  post '/rooms/add_answer' => "boards#add_answer"
  get '/rooms/build/:id' => "boards#build", :as => :build_board
  get '/rooms/:id/design' => "boards#design", :as => :design_board
  get '/rooms/:id/design2' => "boards#design2", :as => :design_board2
  get '/rooms/:id/preview' => "boards#preview", :as => :preview_board
  get '/colors/get_color/:swatch_val' => "colors#get_color", :as => :get_color_by_swatch
  get '/products/:id/product_with_variants' => "products#product_with_variants", :as => :product_with_variants

  get '/widget/room/:id' => "widget#room", :as => :room_widget

  get '/inbox' => "mailbox#inbox", :as => :mailbox_inbox
  get '/sentbox' => "mailbox#sentbox", :as => :mailbox_sentbox
  get '/conversation/:id' => 'mailbox#conversation', :as => :mailbox_conversation

  #post '/registration_subscribers' => 'user_registrations#registration_subscribers', :as => :registration_subscribers
  devise_scope :spree_user do
    post '/registration_subscribers' => 'user_registrations#registration_subscribers', :as => :registration_subscribers
    #, :constraints => { :protocol => "https"}
  end
  resources :subscribers, :only => [:new, :create] do
    collection do
      post :login_or_create
      post :login_user
    end
  end

  #get "/boards/product_search" => "boards#product_search", :as => :board_product_search


  match "/boards/submit_for_publication/:id", to: "boards#submit_for_publication", :as => "submit_for_publication", via: :patch
  namespace :admin do



    #match "/board_products", to: "board_products#update", via: :put
    match "/board_products/mark_approved", to: "board_products#mark_approved", via: :post
    match "/board_products/mark_rejected", to: "board_products#mark_rejected", via: :post

    match "/boards/approval_form", to: "boards#approval_form", via: :get
    match "/boards/revision_form", to: "boards#revision_form", via: :get

    match "/boards/approve", to: "boards#approve", via: :post
    match "/boards/request_revision", to: "boards#request_revision", via: :post

    get "/boards/search" => "boards#search", :as => :board_search
    get "/suppliers/search" => "boards#search_supplier", :as => :supplier_search


    get  "boards/list" => "boards#list", :as => :boards_list
    match  "boards/products(/:status)" => "boards#products", :as => :boards_products, :via =>[:get, :post]
    resources :boards
    resources :board_products
    resources :designer_registrations
    resources :slides

    get "room_designers" => "designer_registrations#room_designers", :as => :room_designers
    get "trade_program" => "designer_registrations#trade_program", :as => :trade_program

    get  "designers" => "users#designers", :as => :designers

    # Product Import Tables
    get  "product_import" => "product_import#index", :as => :product_import
    post "product_import" => "product_import#upload", :as => :post_product_import

    resources :import_tables
    resources :import_logs

    post 'import_tables/:id' => 'import_tables#merge', :as => :create_products_from_csv
    get 'import_tables/:id/results' => 'import_tables#results', as: :import_table_results
    get 'import_tables/:id/percent_complete' => 'import_tables#completion', as: :import_table_completion
  end

end
