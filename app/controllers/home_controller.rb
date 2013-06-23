class HomeController < ApplicationController
  skip_authorization_check
  
  def index_new
    @top_menu_page = :home
    
    render :action => "index_new", :layout => false
  end
  
  def index_old
    render :action => "index", :layout => true
  end

  def access_denied
    
  end
end
