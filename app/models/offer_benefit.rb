# == Schema Information
# Schema version: 20120122055753
#
# Table name: offer_benefits
#
#  id         :integer         not null, primary key
#  type       :string(255)
#  created_at :datetime
#  updated_at :datetime
#  offer_id   :integer
#

class OfferBenefit < ActiveRecord::Base
end
