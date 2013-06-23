# == Schema Information
# Schema version: 20120109004045
#
# Table name: subscriptions
#
#  id                            :integer         not null, primary key
#  start_date                    :datetime
#  end_date                      :datetime
#  user_id                       :integer
#  duration_in_months            :integer
#  created_at                    :datetime
#  updated_at                    :datetime
#  chargeable_unit_properties_id :integer
#

class Subscription < ActiveRecord::Base
  include RelatedToOneChargeableProperties

  belongs_to :user # technically not necessary? Perhaps better than just grabbing from the first box.
  has_many :storage_charges
  
  validates_presence_of :chargeable_unit_properties
  
  def started?
    start_date != nil
  end
  
  def start_subscription
    update_attribute(:start_date, Date.today)
    update_attribute(:end_date, Date.today >> duration_in_months)
  end
  
  def applies_on(date)
    return !start_date.nil? && start_date.to_date <= date \
                            && ((!end_date.nil? && end_date.to_date >= date) \
                                || (end_date.nil? && date <= (start_date.to_date >> duration_in_months.months)))
  end
end
