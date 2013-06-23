# == Schema Information
# Schema version: 20120129012225
#
# Table name: user_offer_benefits
#
#  id               :integer         not null, primary key
#  user_offer_id    :integer
#  offer_benefit_id :integer
#  type             :string(255)
#  created_at       :datetime
#  updated_at       :datetime
#

class FreeSignupUserOfferBenefit < UserOfferBenefit
  has_many :applied_to_boxes, :class_name => "Box"
  belongs_to :user_offer
  # this is necessary because the parent won't instantiate the right class
  belongs_to :offer_benefit, :class_name => "FreeSignupOfferBenefit"
  
  def applies_to_boxes?
    true
  end
  
  def benefit_used_messages    
    applied_to_boxes.collect {|box| "box #{box.box_num} applied on #{box.created_at.strftime '%m/%d/%Y'}" }
  end
  
  def benefit_remaining_messages
    if offer_benefit.num_boxes <= applied_to_boxes.size
      return []
    else
      return ["Free sign-up for #{offer_benefit.num_boxes - applied_to_boxes.size} boxes"]
    end
  end
  
  def used?
    applied_to_boxes.size > 0
  end
  
  def benefit_remaining?
    unused_box_count > 0
  end
  
  def unused_box_count
    offer_benefit.num_boxes - applied_to_boxes.size
  end
  
  def consume_benefit(quantity, boxes_to_which_to_apply, save_ind=false)
    boxes_to_which_to_apply.select {|box| box.free_signup_user_offer_benefit.nil? }.each do |box|
      box.free_signup_user_offer_benefit = self
      if save_ind
        box.save
      end
      quantity -= 1
      break if quantity == 0
    end
    
    self.save if save_ind
  end
  
  def consume_benefit!(quantity, boxes_to_which_to_apply)
    consume_benefit(quantity, boxes_to_which_to_apply, true)
  end
  
  def consume_remaining_benefit(boxes_to_which_to_apply)
    consume_benefit(unused_box_count, boxes_to_which_to_apply)
  end
  
  def consume_remaining_benefit!(boxes_to_which_to_apply)
    consume_benefit!(unused_box_count, boxes_to_which_to_apply)
  end
end
