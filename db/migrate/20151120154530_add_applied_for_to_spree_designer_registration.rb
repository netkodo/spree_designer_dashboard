class AddAppliedForToSpreeDesignerRegistration < ActiveRecord::Migration
  def change
    add_column :spree_designer_registrations, :applied_for, :string
  end
end
