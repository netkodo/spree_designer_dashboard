collection @wall_colors
attributes :id, :board_id, :top_left_x, :top_left_y, :z_index, :status, :width, :height, :center_point_x, :center_point_y, :flip_x, :rotation_offset, :color, :slug, :wall_color
node :image_base64 do |image|
    base64 = "data:image/jpeg;base64,#{Base64.encode64(open(image.wall_color.to_s).read)}"
end
