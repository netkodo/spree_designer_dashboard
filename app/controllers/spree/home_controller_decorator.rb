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
      @review_check = Spree::Review.find_by(token: params[:token])
      @product = Spree::Product.find_by(id: @review_check.product_id)

      @review = @product.product_reviews.new
    end

    def create_user_review
      @review = Spree::Review.find_by(token: params[:token])
      @product = Spree::Product.find_by(id: @review.product_id)
      @order = Spree::Order.find_by(id: @review.order_id)
      @user = Spree::User.find_by(id: @review.user_id)

      if !@user.first_name.present? and !@user.last_name.present?
        user_name = "#{@order.billing_firstname} #{@order.billing_lastname}" if @order.present?
      else
        user_name = "#{@user.full_name}" if @user.present?
      end

      @user_review = @product.product_reviews.new(rating: params[:product_review][:rating], text: params[:product_review][:text],reviewer_name:user_name)


      if params[:images].present? and @user_review.valid?
        params[:images].each do |image|
          if image.present?
            review_image = @user_review.review_images.new(review_image:image)
            Rails.logger.info "*********************\ndone\n" if review_image.save
          end
        end
      end

      respond_to do |format|
        if @user_review.save and @review.update(used: true)
          Resque.enqueue NewQuestionReviewEmail,"support@scoutandnimble.com",'question-review-email',"New product review by #{params[:product_review][:reviewer_name]}:",product.name,params[:product_review][:text] if Rails.env != "staging"
          format.json {render json: @user_review, status: :ok}
        else
          format.json {render json: @user_review.errors, status: :unprocessable_entity}
        end
      end
    end

  end
end