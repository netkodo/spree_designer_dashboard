class Spree::CustomTearSheet < ActiveRecord::Base

  belongs_to :board_product

  scope :custom, -> (field) { where(key: field) }

  def self.create_or_update_tear_sheet(board,params)
    invoice_line_fields = ['sku','name']
    board_products = board.board_products.includes(:custom_tear_sheets)
    board_products.each do |bp|

      params[bp.id.to_s].each do |key,values|
        if key.in?(invoice_line_fields)
          hash = {"#{key}" => values['value'], "#{key}_visible" => values['visible']}
          update_invoice_line(bp,hash)
        else
          if bp.custom_tear_sheets.present?
            update_or_create_cts(bp.id, key, values)
          else
            create_cts(bp.id, key, values)
          end
        end
      end

    end

  end

  def self.update_invoice_line(bp, hash)
    bp.invoice_line.present? ? bp.invoice_line.send(:update_columns, hash) : bp.create_invoice_line(hash)
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