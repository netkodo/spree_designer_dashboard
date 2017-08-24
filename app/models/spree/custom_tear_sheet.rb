class Spree::CustomTearSheet < ActiveRecord::Base

  belongs_to :board_product

  scope :custom, -> (field) { where(key: field) }

  def self.create_or_update_tear_sheet(board,params)
    invoice_line_fields = ['sku','name']
    board_products = board.board_products.includes(:custom_tear_sheets)
    board_products.each do |bp|

      params[bp.id.to_s].each do |key,values|
        if bp.custom_tear_sheets.present?
          create_or_update_cts(bp.id, key, values)
        else
          if key.in?(invoice_line_fields)
            bp.invoice_line.present? ? bp.invoice_line.update_columns(name: values['value'] ,name_visible: values['visible'] ) : bp.create_invoice_line(name: values['value'] ,name_visible: values['visible'] )
          else
            create_cts(bp.id, key, values)
          end
        end
      end

    end

  end

  def self.create_cts(bp_id, key, values)
    Spree::CustomTearSheet.create({board_product_id: bp_id, key: key.gsub('_',' ')}.merge(values))
  end

  def self.update_or_create_cts(bp_id, key, values)
    if Spree::CustomTearSheet.where(key: key.gsub('_',' '), board_product_id: bp_id).present?
      Spree::CustomTearSheet.where(key: key.gsub('_',' '), board_product_id: bp_id).first.update({board_product_id: bp_id, key: key}.merge(values))
    else
      create_cts(bp_id, key, values)
    end
  end

end