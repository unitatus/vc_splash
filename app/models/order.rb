# == Schema Information
# Schema version: 20110913051413
#
# Table name: orders
#
#  id                            :integer         not null, primary key
#  cart_id                       :integer
#  ip_address                    :string(255)
#  user_id                       :integer
#  created_at                    :datetime
#  updated_at                    :datetime
#  initial_charged_shipping_cost :float
#

class Order < ActiveRecord::Base
  belongs_to :cart
  has_many :payment_transactions, :dependent => :destroy
  has_many :order_lines, :dependent => :destroy
  belongs_to :user
  has_many :charges, :dependent => :destroy
  has_many :invoices, :dependent => :destroy
  
  before_destroy :destroy_associated_shipments
  
  attr_accessible :user_id, :created_at

  def purchase()
    transaction_successful = false

    self.transaction do
      self.initial_charged_shipping_cost = cart.quoted_shipping_cost      
      
      if (!save)
        raise ActiveRecord::Rollback
      end
      
      charges, credits = do_pre_payment_processing
      
      if total_in_cents > 0.0
        payment_transaction = pay_for_order(charges, credits)
      end
      
      # If this gets a DB error an uncaught exception will be thrown, which should kill the transaction
      do_post_payment_processing(charges, credits, payment_transaction)

      transaction_successful = true 
    end # end transaction so we don't re-enter this section

    return transaction_successful
  end
  
  def initial_charged_shipping_cost
    return_val = read_attribute(:initial_charged_shipping_cost)
    if return_val.nil?
      return_val = 0.0
    end
    
    return return_val
  end
  
  def contains_ship_charge_items
    ship_charge_items = order_lines.select { |o| o.product.customer_pays_shipping_up_front? }
    return !ship_charge_items.empty?
  end
  
  def contains_item_mailings?
    item_mailing_items = order_lines.select { |o| o.product.item_mailing? }
    return !item_mailing_items.empty?
  end
  
  def unpaid_mail_item_lines
    order_lines.select { |o| o.item_mailing? && o.item_mail_shipping_charge.nil? }
  end
  
  def free_shipping?
    order_lines.each do |line|
      if !line.discount.free_shipping?
        return false
      end
    end
    
    return true
  end
  
  def contains_only_ordered_boxes
    the_ordered_box_lines = self.ordered_box_lines
    
    return the_ordered_box_lines.size > 0 && the_ordered_box_lines.size == self.order_lines.size
  end
  
  def contains_ordered_boxes
    ordered_box_lines.size > 0 
  end
  
  def ordered_box_lines
    self.order_lines.select { |order_line| order_line.product.box? }
  end
  
  # at this time there is no way for a customer to order a shippable item other than by walking through the website, so there will always be a cart for this
  def quoted_shipping_cost_success
    return cart.nil? || cart.quoted_shipping_cost_success
  end
  
  def process_order_lines(order_line_ids, charity_names=Hash.new)
    order_lines = Array.new
    
    self.transaction do
  
      order_line_ids.each do |order_line_id|
        order_line = OrderLine.find(order_line_id)
        order_lines << order_line
    
        # will save the order line
        order_line.process(charity_names[order_line.id])
      end
      
      UserMailer.deliver_order_lines_processed(user, order_lines)
      
      return order_lines
    end # end transaction
  end

  def total_in_cents
    the_total = 0.0
    
    order_lines.each do |order_line|
      the_total += order_line.discount.prepaid_at_purchase*100 + order_line.discount.charged_at_purchase*100
    end
    
    the_total + self.initial_charged_shipping_cost*100
  end
  
  def amount_paid
    the_amount = 0.0
    
    payment_transactions.each do |transaction|
      the_amount += transaction.credit.amount if transaction.credit
    end
    
    return the_amount
  end
  
  def amount_charged
    the_amount = 0.0
    
    charges.each do |charge|
      the_amount += charge.total_in_cents
    end
    
    return the_amount/100
  end
  
  def build_order_line(attributes={})
    order_line = order_lines.build(:attributes => attributes)

    order_line.order_id = id
    
    order_line
  end
  
  def status    
    order_lines.each do |order_line|
      if order_line.status == OrderLine::NEW_STATUS
        return OrderLine::NEW_STATUS
      end
    end
    
    return OrderLine::PROCESSED_STATUS
  end
  
  # this method saves the charges
  # This generates all the charges -- but ignores any prepayments necessary (such as when ordering new boxes)
  def generate_charges_and_credits
    raise "Attempted to call generate charges on unsaved order" unless self.id
    charges = Array.new
    credits = Array.new

    order_lines.each do | order_line |
      if order_line.associated_boxes.size > 0 # this is a box-related order
        order_line.associated_boxes.each do |box|
          if order_line.discount.charged_at_purchase > 0 # we only charge for stuff that is charged at purchase, though we may pay for things that are prepaid at purchase
            new_charge = Charge.new(:user_id => user_id, :comments => "Charge for " + order_line.product.name)
            new_charge.total_in_cents = ((order_line.discount.charged_at_purchase/order_line.associated_boxes.size)*100).ceil
            new_charge.associate_with(box)
            new_charge.save
            order_line.add_to_amount_paid_at_purchase(new_charge.amount)
            charges << new_charge
          end
        end
      elsif order_line.discount.charged_at_purchase > 0 # this is a non-box related order with a charge
        new_charge = Charge.create!(:user_id => user_id, :total_in_cents => (order_line.discount.charged_at_purchase*100).ceil, :product_id => order_line.product_id, :order_id => self.id, :comments => "Charge for " + order_line.product.name)
        charges << new_charge
        order_line.add_to_amount_paid_at_purchase(new_charge.amount)
      elsif order_line.discount.charged_at_purchase < 0
        credits << Credit.create!(:user_id => user_id, :amount => order_line.discount.charged_at_purchase * -1, :description => "Credit for order line #{order_line.id} for product ""#{order_line.product.name}"".")
        user.consume_credits_for_product(order_line.product, order_line.quantity, box_order_lines.collect {|box_order_line| box_order_line.associated_boxes}.flatten)
      end
    end
    
    # can't associate with shipment id yet because shipment object is only created at shipment
    if !cart.nil? && !cart.quoted_shipping_cost.nil? && cart.quoted_shipping_cost > 0.0
      charges << Charge.create!(:user_id => user_id, :total_in_cents => (self.initial_charged_shipping_cost*100).ceil, :order_id => self.id, :comments => "Shipping charge")
    end
    
    [charges, credits]
  end

  # This method can only be called on order lines with the same address.
  def process_mailing_order_lines(amount, order_lines, comments=nil)
    new_charge = nil
    message = nil
    
    # Validate that all passed order lines have the same address
    last_address = nil
    order_lines.each do |order_line|
      if last_address.nil?
        last_address = order_line.shipping_address
      else
        if last_address != order_line.shipping_address
          raise "Cannot call this method with order lines with multiple shipping addresses"
        end
      end
    end
    
    self.transaction do
      new_charge = Charge.new(:user_id => user.id, :comments => comments, :total_in_cents => amount.to_f*100)

      # a little validation
      order_lines.each do |order_line|
        if order_line.order != self
          raise "Invalid call - order line id for different order."
        end
      
        if order_line.item_mail_shipping_charge
          raise "Invalid call -- order line " + order_line.id.to_s + " already has a shipping charge."
        end
      end

      shipment = generate_item_mail_shipment(order_lines[0].shipping_address, new_charge)
      
      order_lines.each do |order_line|      
        order_line.process(nil, new_charge, shipment)
      end
    
      # associate with this object
      charges << new_charge
    
      # actually attempt to pay
      new_transaction, message = PaymentTransaction.pay(new_charge.amount, user.default_payment_profile, self.id)
    
      # if transaction failed we won't save anything - pop out of the transaction without error
      if new_transaction.nil?
        new_charge = nil
        raise ActiveRecord::Rollback
      end
    
      # transaction was fine; save and return
      new_charge.save
      order_lines.each do |order_line|
        order_line.save
      end
    
      save
      
      UserMailer.deliver_order_lines_processed(user, order_lines)
    end # transaction
    
    return new_charge, message
  end
  
  def generate_item_mail_shipment(to_address_id, shipment_charge)
      shipment = Shipment.new

      shipment.from_address_id = Rails.application.config.fedex_vc_address_id
      shipment.to_address_id = to_address_id
      shipment.payor = Shipment::CUSTOMER # TODO: At some point this may change based on customer subscription
      shipment.charge = shipment_charge

      if (!shipment.save)
        raise "Malformed data: cannot save shipment; error: " << shipment.errors.inspect
      end

      begin
        if !shipment.generate_fedex_label
          shipment.destroy
          raise "Malformed data: cannot save shipment; error: " << shipment.errors.inspect
        end
      rescue Fedex::FedexError => e
        # this is actually fine
      end

      shipment
  end
  
  def vc_box_count
    count_lines(Rails.application.config.our_box_product_id)
  end
  
  def vc_box_line
    order_lines.each do |order_line|
      if order_line.vc_box?
        return order_line
      end
    end
    
    return nil
  end
  
  def cust_box_line
    order_lines.each do |order_line|
      if order_line.cust_box?
        return order_line
      end
    end
    
    return nil
  end
  
  def cust_box_count
    count_lines(Rails.application.config.your_box_product_id)
  end
  
  def inv_box_count
    count_lines(Rails.application.config.our_box_inventorying_product_id) + count_lines(Rails.application.config.your_box_inventorying_product_id)
  end
  
  def count_lines(product_id)
    total = 0
    
    order_lines.each do |order_line|
      total += order_line.quantity if order_line.product_id == product_id
    end
    
    total
  end
    
  # Typically, we would just do a before_destroy, or destroy the cart first. Two problems: (1) the order is usually the starting point for administration,
  # so it doesn't make sense to destroy the cart first; and (2) Webrick dies when I call order.destroy directly for who knows what reason. Same thing if I 
  # call self.destroy as the first call in my method. I have to do the cart stuff first. Bizarre.
  def destroy_test_order! 
    cart = self.cart
    # inventory orders don't have a cart
    if cart
      cart.cart_items.each do |cart_item|
        cart_item.destroy
      end
      cart.destroy
    end
    
    self.destroy
  end
  
  def latest_invoice
    the_invoices = invoices
    
    if the_invoices.size == 0
      return nil
    # elsif the_invoices.size == 1
    #   return the_invoices[0]
    else
      sorted_invoices = the_invoices.sort {|x,y| y.created_at <=> x.created_at }
      return sorted_invoices.last
    end
  end
  
  def contains_box_orders?
    return box_order_lines.size > 0
  end
  
  def contains_box_services?
    return contains_box_orders? || contains_box_return_services? || contains_inventory_services?
  end
  
  def contains_box_return_services?
    box_return_lines.size > 0
  end
  
  def contains_inventory_services?
    inventory_lines.size > 0
  end
  
  def contains_item_services?
    item_service_lines.size > 0
  end
  
  def item_service_lines
    order_lines.select { |order_line| order_line.product.item_service? }
  end
  
  def inventory_lines
    order_lines.select { |order_line| order_line.product_id == Rails.application.config.your_box_inventorying_product_id || order_line.product_id == Rails.application.config.our_box_inventorying_product_id }
  end
  
  def box_order_lines
    order_lines.select { |order_line| order_line.product_id == Rails.application.config.your_box_product_id || order_line.product_id == Rails.application.config.our_box_product_id }
  end
  
  def box_return_lines
    order_lines.select { |order_line| order_line.product_id == Rails.application.config.return_box_product_id }
  end
  
  def cust_order_lines
    order_lines.select { |order_line| order_line.cust_box? }
  end
  
  def vc_order_lines
    order_lines.select { |order_line| order_line.vc_box? }
  end
  
  def customer_boxes
    ordered_boxes = Array.new
    cust_order_lines.each do |order_line|
      ordered_boxes = ordered_boxes | order_line.ordered_boxes
    end
    
    return ordered_boxes
  end
  
  def vc_boxes
    ordered_boxes = Array.new
    vc_order_lines.each do |order_line|
      ordered_boxes = ordered_boxes | order_line.ordered_boxes
    end
    
    return ordered_boxes
  end
  
  def customer_box_qty
    total = 0
    cust_order_lines.each do |order_line|
      total += order_line.quantity
    end
    
    return total
  end
  
  def vc_box_qty
    total = 0

    vc_order_lines.each do |order_line|
      total += order_line.quantity
    end
    
    return total    
  end
  
  private
  
  # This method saves the transactions
  # We must pay for any charges plus any prepayments
  def pay_for_order(charges, credits)
    amount = 0.0
    
    #calculate the prepayments
    order_lines.each do |order_line|
      prepay_amt = order_line.discount.prepaid_at_purchase
      amount += prepay_amt
      order_line.add_to_amount_paid_at_purchase(prepay_amt)
    end
    
    # calculate the charges
    charges.each do |charge|
      amount += charge.amount
    end
    
    # subtract the credits
    credits.each do |credit|
      amount -= credit.amount
    end
    
    if amount <= 0.0
      return nil
    end
    
    new_transaction, message = PaymentTransaction.pay(amount, user.default_payment_profile, self.id)
    
    if new_transaction.nil?
      errors.add("cc_response", message)
      raise ActiveRecord::Rollback
    end
    
    return new_transaction
  end
  
  # this method throws a RuntimeError b/c the only way that save wouldn't work is if something went really wrong
  # and we don't want to miss that.
  def do_pre_payment_processing
    cart.mark_ordered
    
    if (!cart.save)
      raise "Unable to save cart. Cart: " << cart.inspect
    end
    
    process_box_orders
    process_box_returns
    process_item_services
        
    generate_charges_and_credits # if any
  end

  # this method throws a RuntimeError b/c the only way that save wouldn't work is if something went really wrong
  # and we don't want to miss that.
  def do_post_payment_processing(charges, credits, payment_transaction)
    invoice = create_invoice(charges, credits, payment_transaction)

    UserMailer.deliver_invoice_email(user, invoice, true)
  end # end function
  
  def create_invoice(charges, credits, payment_transaction)
    invoice = Invoice.new()
    
    invoice.user = user
    invoice.payment_transaction = payment_transaction
    invoice.order = self
    
    if !invoice.save
      raise "Unable to create invoice; errors: " << invoice.errors.inspect
    end
    
    invoice
  end
  
  def process_box_returns
    box_return_lines.each do |order_line|
      order_line.service_box.mark_for_return
    end
  end
  
  def process_item_services
    item_service_lines.each do |order_line|
      order_line.service_item.process_service(order_line.product)
    end
  end
  
  def process_box_orders
    box_order_lines.each do |order_line|
      if order_line.product.vc_box?
        type = Box::VC_BOX_TYPE
        status = Box::NEW_STATUS
      elsif order_line.product.cust_box?
        type = Box::CUST_BOX_TYPE
        status = Box::BEING_PREPARED_STATUS
        order_line.update_attribute(:status, OrderLine::PROCESSED_STATUS) # no further work by us is necessary
      end

      for i in 1..(order_line.quantity)
        new_box = Box.new(:assigned_to_user_id => user.id, :ordering_order_line_id => order_line.id, :status => status, :box_type => type, \
          :inventorying_status => Box::NO_INVENTORYING_REQUESTED)
        if !new_box.save
          raise "Standard box creation failed."
        end

        if order_line.committed_months && order_line.committed_months > 1
          new_box.subscriptions.create!(:duration_in_months => order_line.committed_months, :user_id => self.user_id)
        end
      end # inner for loop
    end
    
    stocking_fee_lines.each do |stocking_fee_line|
      stocking_fee_line.update_attribute(:status, OrderLine::PROCESSED_STATUS)
    end
  end
  
  def stocking_fee_lines
    order_lines.select {|order_line| order_line.product.stocking_fee? }
  end
  
  def destroy_associated_shipments
    order_lines.each do |order_line|
      order_line.shipment.destroy if order_line.shipment
    end
  end
end
