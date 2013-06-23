class AccountController < ApplicationController
  # The account controller actions are only accessible for someone who is signed up as a user.
  authorize_resource :class => false

  before_filter :set_menu

  def ssl_required?
    # needs to change to true if the site goes live again
    false
  end

  def index
    @last_payment_transaction = current_user.last_successful_payment_transaction
    # this must be called before the next line, which will alter (but not save) the user
    @next_user_charge_date = current_user.next_charge_date
    user = current_user

    user.calculate_subscription_charges

    account_balance = user.account_balance_as_of(DateHelper.end_of_month, true)
    @next_user_charge = account_balance > 0 ? 0 : account_balance * -1
  end
  
  def invoice_estimate
    @user = current_user

    @user.calculate_subscription_charges # this will add all the charges that will show up at the end of the month
    @start_of_month = DateHelper.start_of_month
    @end_of_month = DateHelper.end_of_month
  end
  
  def account_history
    @events = Event.all(current_user)
  end
  
  def prep_pricing_explainer(order=nil)
    if order
      box_line = order.vc_box_line
      if box_line.nil?
        box_line = order.cust_box_line
        if box_line
          @type = Box::CUST_BOX_TYPE
        end
      else
        @type = Box::VC_BOX_TYPE
      end
    else
      box_line = current_user.cart.vc_box_line
      if box_line.nil?
        box_line = current_user.cart.cust_box_line
        if box_line
          @type = Box::CUST_BOX_TYPE
        end
      else
        @type = Box::VC_BOX_TYPE
      end
    end
    
    @old_count = @type == Box::VC_BOX_TYPE ? current_user.stored_box_count(@type) : current_user.cust_cubic_feet_in_storage
    @new_count = box_line ? box_line.quantity : nil
    @new_cost = box_line ? box_line.discount.total_monthly_price_after_discount : nil
    @due_now = box_line ? box_line.discount.prepaid_at_purchase : nil
    @discount_perc = box_line ? box_line.discount.unit_discount_perc : nil
    @discount_perc_sans_commitment = box_line ? Discount.new(box_line.product, @new_count, 0, @old_count).unit_discount_perc : nil
    @committed_months = box_line ? box_line.discount.month_count : nil
    @committed_months_discount = box_line ? Discount.new(box_line.product, 1, box_line.discount.month_count, 0).unit_discount_perc : nil
  end
  
  def store_more_boxes
    # If you circumvented the normal sign-up procedures then you must take care of those now
    if current_user.default_shipping_address.nil?
      @address = Address.new
      @user = current_user
      flash[:notice] = "You must create a default shipping address first."
      render "addresses/new_default_shipping_address" and return
    elsif current_user.default_payment_profile.nil?
      @profile = PaymentProfile.new
      @addresses = current_user.addresses
      render "payment_profiles/new_default_payment_profile" and return
    end
    
    @your_box = Product.find(Rails.application.config.your_box_product_id)
    @our_box = Product.find(Rails.application.config.our_box_product_id)

    @cart = Cart.find_active_by_user_id(current_user.id)
    @cart = Cart.new unless @cart
  end

  def order_boxes
    @cart = Cart.find_active_by_user_id(current_user.id)
    if (@cart.nil?)
      @cart = Cart.new
      @cart.user_id = current_user.id
    else
      @cart.remove_cart_item(Rails.application.config.our_box_product_id)
      @cart.remove_cart_item(Rails.application.config.your_box_product_id)
      @cart.remove_cart_item(Rails.application.config.our_box_inventorying_product_id)
      @cart.remove_cart_item(Rails.application.config.your_box_inventorying_product_id)
      @cart.remove_cart_item(Rails.application.config.stocking_fee_product_id)
    end
    
    if params[:box_type] == "vc_boxes"
      box_product_id = Rails.application.config.our_box_product_id
      num_boxes = params[:num_vc_boxes][:num_vc_boxes]
    elsif params[:box_type] == "cust_boxes"
      box_product_id = Rails.application.config.your_box_product_id
      num_boxes = params[:num_cust_boxes][:num_cust_boxes]
    else
      raise "Illegal box type selected."
    end    
    
    # We no longer have discounts, so committed months is set to zero. Leaving it in in case we change back to discounts.
    committed_months = 1
    
    @cart.add_cart_item(box_product_id, num_boxes, committed_months)
    
    # The following code is for the cart maintenance pages, which as of 8/17/2011 are turned off.
    if (@cart.save())
      flash[:notice] = "Cart updated. Click the cart option on the left to see cart contents and finalize order."
    else
      flash[:alert] = "There was a problem saving your update to the cart."
      @your_box = Product.find(Rails.application.config.your_box_product_id)
      @our_box = Product.find(Rails.application.config.our_box_product_id)
      render :store_more_boxes
      return
    end

    if @cart.cart_items.size == 0
      @your_box = Product.find(Rails.application.config.your_box_product_id)
      @our_box = Product.find(Rails.application.config.our_box_product_id)
      @cart.errors[:cart] = "Please enter at least one positive integer."
      render :store_more_boxes
    else
      redirect_to :action => 'check_out'
    end
  end
  
  def external_addresses_validate
    
  end

  def cart
    @turn_cart_off = true
    @cart = Cart.find_active_by_user_id(current_user.id)
    if (@cart.nil?)
      @cart = Cart.new
    end
  end

  def update_cart_item
    @turn_cart_off = true
    if (params[:quantity] == '0')
      remove_cart_item
      return
    end

    cart_item = CartItem.find(params[:cart_item_id])
    stocking_fee_item = cart_item.cart.stocking_fee_line

    cart_item.quantity = params[:quantity]
    stocking_fee_item.quantity = params[:quantity] if stocking_fee_item

    if (cart_item.save())
      stocking_fee_item.save if stocking_fee_item
      flash.now[:notice] = "Cart item quantity updated to #{cart_item.quantity}!"
    else
      flash.now[:alert] = "There was a problem saving your update."
      @errors = cart_item.errors
    end

    @cart = Cart.find(cart_item.cart_id)

    render 'cart'
  end

  def remove_cart_item
    # find the cart so we can re-show the page
    begin
      cart_item = CartItem.find(params[:cart_item_id])
    rescue
      # the user probably just hit refresh
      @cart = current_user.cart
      return
    end
   
    if cart_item.deletable?
      CartItem.delete(params[:cart_item_id])
      flash.now[:notice] = "Cart item removed."
    end

    @cart = Cart.find(cart_item.cart_id)

    render 'cart'
  end

  def check_out_remove_cart_item
    CartItem.delete(params[:id])
    redirect_to :action => "check_out"
  end

  def check_out
    @cart = current_user.cart
    @turn_cart_off = true
    
    if !@cart || @cart.cart_items.empty?
      redirect_to :action => :store_more_boxes
      return
    end

    @cart.quote_shipping
    
    @addresses = current_user.addresses
    
    if @addresses.nil? || @addresses.empty?
      @address = Address.new
      render :action => "add_new_shipping_address"
      return
    elsif current_user.default_payment_profile.nil?
      @profile = PaymentProfile.new
      @addresses = current_user.addresses
      render "payment_profiles/new_default_payment_profile" and return
    end
    
    @order = Order.new
    
    prep_pricing_explainer
    
    render :check_out
  end

  def add_new_shipping_address
    @address = Address.new
    @address.user_id = current_user.id
  end
  
  def double_checkout
    
  end
  
  def checkout_add_offer_code
    if !params[:offer_code].blank?
      @user = current_user
      
      if @user.apply_offer_or_coupon_code(params[:offer_code])
        flash[:notice] = ["Offer '#{params[:offer_code]}' applied and reflected in totals."]
      else
        flash[:notice] = @user.errors[:offer_code]
      end 
    end
    
    check_out
  end

  def finalize_check_out
    @cart = current_user.cart
    check_cart = params[:cart_id].blank? ? nil : Cart.find(params[:cart_id])

    if @cart.nil? || check_cart != @cart
      render :double_checkout and return
    elsif @cart.order # this means we failed the last time through, after the payment was created; be nice about it!
      @order = @cart.order
    else
      @order = @cart.build_order(params[:order])
    end
    
    @order.ip_address = request.remote_ip      
    
    if @order.contains_box_orders?
      # the only way to get to this function is if the user saw the member agreement; take note of that
      if params[:agreed] == "1"
        current_agreement = RentalAgreementVersion.latest
        user = current_user
        if !user.rental_agreement_versions.include? current_agreement
          user.rental_agreement_versions << current_agreement
        end
      else
        @order.errors.add(:agreement, "You must agree to the rental agreement to proceed.")
        fail_checkout
        return
      end
    end
    
    if (!@order.purchase) # this saves the order
      fail_checkout
    end
    
    @cart = nil
    prep_pricing_explainer(@order)
  end
  
  def fail_checkout
    render 'check_out'    
  end
  
  private 
  
  def set_menu
    @top_menu_page = :account
  end
  
  def get_last_order(user_id=nil, not_null_field)
    if user_id.nil? && @current_user
      user_id = @current_user.id
    elsif user_id.nil?
      return nil
    end
    
    begin
      Order.find(:all, :conditions => "user_id = #{user_id} and #{not_null_field} is not null", :order => "created_at desc", :limit => 1).first
    rescue ActiveRecord::RecordNotFound
      return nil
    end
  end
end
