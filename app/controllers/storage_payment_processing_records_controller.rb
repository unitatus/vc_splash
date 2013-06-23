class StoragePaymentProcessingRecordsController < ApplicationController
  authorize_resource

  def ssl_required?
    # needs to change to true if app is turned back on
    false
  end
  
  def show
    @admin_page = :monthly_charges
    @record = StoragePaymentProcessingRecord.find(params[:id])
  end
  
  def index
    @admin_page = :monthly_charges
    @records = StoragePaymentProcessingRecord.all
  end
end
