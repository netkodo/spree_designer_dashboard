collection @board_products
attributes :id, :height, :rotation_offset, :top_left_x, :top_left_y, :width, :z_index, :center_point_x, :center_point_y, :flip_x
image_id = ""
node :board_product do |board_product|
   image_id = board_product.image_id
end
child  :product do
  attributes :slug, :name, :description
    node :image_url do |p|
      image = Spree::Image.where(id: image_id).first
       if image.present?
         image.attachment.url
         "data:image/jpeg;base64,#{Base64.encode64(open(image.attachment.url.to_s).read)}"
       else
         p.images.first.attachment.url if !p.images.blank? and p.images.first.attachment
          "data:image/jpeg;base64,#{Base64.encode64(open( p.images.first.attachment.url.to_s).read) if !p.images.blank? and p.images.first.attachment}"
       end
    end
end


