module Spree
  HomeController.class_eval do
    # before_filter :require_authentication
    
    def home2
      @slides = Spree::Slide.current.order("created_at desc") || Spree::Slide.defaults
      @page_photos = Spree::PagePhoto.where(active: true)
      @arrive_product = Spree::Product.where(new_arrival: true).where("new_arrival_until >= ?", DateTime.now.to_date).limit(20)
      @arrive_product = Spree::Product.all.order('created_at desc').limit(12) if @arrive_product.count <= 12
      @designers = Spree::User.published_designers().order("created_at desc")
      @promoted_rooms = Spree::Board.promoted.limit(6)
      @home_text = Spree::HomeText.first
    end

    def user_review
      @review = Spree::Review.find_by(token: params[:token])
      @product = Spree::Product.find_by(id: @review.product_id)
      @user = Spree::User.find_by(id: @review.user_id)
    end

    def create_user_review
      @product = Spree::Product.find_by(slug: params[:slug])
      @review = Spree::Review.find_by(token: params[:token])
      @user_review = @product.product_reviews.new(rating: params[:review_rating], text: params[:review_text],reviewer_name: params[:reviewer_name])
      Rails.logger.info params
      Rails.logger.info "**********************"

      respond_to do |format|
        if @user_review.save and @review.update(used: params[:used])
          format.json {render json: @review}
        else
          format.json {render json: @review.errors}
        end
      end
    end
  end
end