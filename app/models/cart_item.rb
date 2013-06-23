# == Schema Information
# Schema version: 20111023204639
#
# Table name: cart_items
#
#  id               :integer         not null, primary key
#  quantity         :integer
#  cart_id          :integer
#  product_id       :integer
#  created_at       :datetime
#  updated_at       :datetime
#  committed_months :integer
#  box_id           :integer
#  address_id       :integer
#  stored_item_id   :integer
#

class CartItem < ActiveRecord::Base
  belongs_to :product
  belongs_to :cart
  belongs_to :box
  belongs_to :address
  belongs_to :stored_item

  validates_numericality_of :quantity, :only_integer => true, :greater_than_or_equal_to => 0, :message => "Please enter only positive integers."
  
  validates_presence_of :product_id
  
  def CartItem.delete(id)
    cart_item = CartItem.find(id)
    if cart_item.product.box?
      stocking_fee_item = cart_item.cart.stocking_fee_line
      stocking_fee_item.destroy
    end
    
    cart_item.destroy
  end
  
  def get_or_pull_address
    if self.address.nil?
      update_attribute(:address_id, cart.user.default_shipping_address_id)
      self.address = cart.user.default_shipping_address
    end 
    
    return self.address
  end
  
  def new_box_line?
    product.box?
  end
  
  def discount?
    return total_unit_price_after_discount > 0 && self.discount.unit_discount_perc > 0.0
  end
  
  def shippable?
    return self.product.shippable?
  end
  
  def deletable?
    return self.product_id != Rails.application.config.stocking_fee_product_id && self.product_id != Rails.application.config.stocking_fee_waiver_product_id
  end
  
  def customer_pays_shipping_up_front?
    return self.product.customer_pays_shipping_up_front?
  end
  
  def discount
    # Box will return nil for non-box products, which is then translated as "any type" in the user method, which doesn't really matter for other products, since they are one-off
    Discount.new(product, quantity, committed_months, cust_box? ? cart.user.cust_cubic_feet_in_storage : cart.user.stored_box_count(Box.get_type(product)))
  end
  
  def cust_box?
    product.cust_box?
  end
  
  def vc_box?
    product.vc_box?
  end
  
  def item_service?
    self.product.item_service?
  end
  
  def donation?
    self.product.donation?
  end
  
  def item_mailing?
    self.product.item_mailing?
  end
  
  def description
    if !self.box.nil?
      product.name + " for box " + box.box_num.to_s
    elsif !self.stored_item.nil?
      product.name + " for stored item " + stored_item.id.to_s
    else
      product.name
    end
  end
  
  def total_unit_price_after_discount
    discount.unit_price_after_discount * self.quantity
  end
  
  def box_type
    if product.cust_box?
      Box::CUST_BOX_TYPE
    elsif product.vc_box?
      Box::VC_BOX_TYPE
    else
      nil
    end
  end

  # This method exists based on the expectation that cart items could hold boxes or individual items
  def weight
    if box
      box.weight * self.quantity
    else
      raise "Weight not known."
    end
  end
  
  def height    
    if box
      if quantity > 1
        raise "Cannot calculate height on more than one item at a time."
      end
      
      box.height
    else
      return nil
    end
  end
  
  def width
    if box
      if quantity > 1
        raise "Cannot calculate height on more than one item at a time."
      end
      
      box.width
    else
      return nil
    end
  end
  
  def length
    if box
      if quantity > 1
        raise "Cannot calculate height on more than one item at a time."
      end
      
      box.length
    else
      return nil
    end
  end
end
