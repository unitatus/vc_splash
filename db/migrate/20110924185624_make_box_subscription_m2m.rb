class MakeBoxSubscriptionM2m < ActiveRecord::Migration
  def self.up
    create_table :boxes_subscriptions, :id => false do |t|
          t.integer :box_id, :references => :boxes
          t.integer :subscription_id, :references => :subscriptions
    end
    
    add_index :boxes_subscriptions, :box_id
    add_index :boxes_subscriptions, :subscription_id
   
    # This interim state does not work with current object model - removed code while reconstituting site on June 21, 2013 
    #boxes_with_subscriptions = Box.all.select { |box| !box.subscription_id.nil? }
    #boxes_with_subscriptions.each do |box|
    #  box.subscriptions << Subscription.find(box.subscription_id)
    #  box.save
    #end
    
    remove_column :boxes, :subscription_id
  end

  def self.down
    add_column :boxes, :subscription_id, :integer, :references => :subscriptions
    
    Box.all.each do |box|
      box.update_attribute(:subscription_id, box.subscriptions.last.id) if box.subscriptions.size > 0
    end
    
    drop_table :boxes_subscriptions
  end
end
