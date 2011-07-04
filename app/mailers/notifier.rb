class Notifier < ActionMailer::Base

  default :from => "The Visible Closet <info@thevisiblecloset.com>"

  def single_email(sender)
    @sender = sender
    mail(:to => "dave@thevisiblecloset.com", :subject => "New distribution list member") 
logger.debug("LEEEEEEERRRRRRROOOOOOOYYYYYYY  JENKINS")
  end
end

