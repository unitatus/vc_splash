# == Schema Information
# Schema version: 20120103033154
#
# Table name: stored_item_photos
#
#  id                 :integer         not null, primary key
#  photo_file_name    :string(255)
#  photo_content_type :string(255)
#  photo_file_size    :integer
#  photo_updated_at   :datetime
#  access_token       :string(255)
#  stored_item_id     :integer
#  created_at         :datetime
#  updated_at         :datetime
#  visibility         :string(255)
#

class StoredItemPhoto < ActiveRecord::Base
  belongs_to :stored_item
  
  has_attached_file :photo, :styles => { 
                              :thumb => "100x100#",
                              :normal => "600x600>",
                              :medium => "150x150>" 
                              },
                            :storage => :s3,
                            :s3_credentials => { 
                                  :access_key_id => Rails.application.config.s3_key,
                                  :secret_access_key => Rails.application.config.s3_secret
                                },
                            # Changed when TVC lost ssl cert
                            #:s3_protocol => :https,
                            :s3_protocol => :http,
                            :path => Rails.application.config.s3_photo_path,
                            :bucket => Rails.application.config.s3_photo_bucket
                            
  validates_attachment_presence :photo
  validates_attachment_content_type :photo, :content_type => [/image\/jpg/, /image\/jpeg/, /image\/pjpeg/, /image\/gif/, /image\/png/, /image\/x-png/]
  before_create :generate_access_token
  
  CUSTOMER_VISIBILITY = :customer
  ADMIN_VISIBILITY = :admin
  
  symbolize :visibility
  
  def StoredItemPhoto.new(attrs=nil)
    photo = super(attrs)
    photo.visibility = ADMIN_VISIBILITY
    return photo
  end
  
  def StoredItemPhoto.visibilities_select
    [[CUSTOMER_VISIBILITY.to_s,CUSTOMER_VISIBILITY.to_s],[ADMIN_VISIBILITY.to_s,ADMIN_VISIBILITY.to_s]]
  end
  
  def default?
    stored_item.default_photo(visibility) == self
  end
  
  def real_photo?
    self.id != Rails.application.config.furniture_stock_photo_id
  end

  private
  
  # simple random salt
  def random_salt(len = 20)
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    salt = ""
    1.upto(len) { |i| salt << chars[rand(chars.size-1)] }
    return salt
  end

  # SHA1 from random salt and time
  def generate_access_token
    self.access_token = Digest::SHA1.hexdigest("#{random_salt}#{Time.now.to_i}")
  end

  # interpolate in paperclip
  Paperclip.interpolates :access_token  do |attachment, style|
    attachment.instance.access_token
  end

end
