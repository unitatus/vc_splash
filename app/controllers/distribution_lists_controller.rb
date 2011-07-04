class DistributionListsController < ApplicationController
  def add
#    Notifier.single_email(params[:sender_email]).deliver
    respond_to do |format|
#      format.html add.html.erb
      format.html # add.html.erb
      format.js 
    end
  end
end
