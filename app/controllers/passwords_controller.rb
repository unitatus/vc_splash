class PasswordsController < Devise::PasswordsController
  
  def ssl_required?
    # needs to change to true if app is turned back on
    false
  end

end
