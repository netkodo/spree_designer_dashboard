class Spree::Admin::SlidesController < Spree::Admin::ResourceController

  before_action :fetch, only: [:edit, :update, :destroy]

  def index
    @current_slides = Spree::Slide.current
    @expired_slides = Spree::Slide.expired
    @upcoming_slides = Spree::Slide.upcoming
  end
  
  def new
    @slide = Spree::Slide.new
    @slide.build_slider_image
  end
  
  def create
    @slide = Spree::Slide.new(slide_params)
    if @slide.save
      redirect_to admin_slides_path
    else
      @slide.build_slider_image
      render action: "new"
    end
  end

  def edit
    @slide.build_slider_image unless @slide.slider_image.present?
  end

  def update
    if @slide.update(slide_params)
      redirect_to edit_admin_slide_path(@slide, notice: 'Your slide was updated.')
    else
      render action: "edit"
    end
  end
  
  def destroy
    respond_to do |format|
      if @slide.destroy
        format.html {redirect_to admin_slide_path(@slide, :notice => 'Your slide was deleted.')}
        format.js {render :nothing => true, :status => 200, :layout => false}
      else
        #format.html { render :action => ""}
      end
    end 
  end

 
  private

  def fetch
    @slide = Spree::Slide.find(params[:id])
  end

  def slide_params
    output = params.require(:slide).permit(:name, :path, :is_default, :published_at, :expires_at, slider_image_attributes: [:attachment])
    # There is additional logic for image_slider so this was neccesary to prevent deletion while edit slide.
    output.extract!(:slider_image_attributes) if params[:slide][:slider_image_attributes].present? and params[:slide][:slider_image_attributes][:attachment].blank?
    output
  end
end