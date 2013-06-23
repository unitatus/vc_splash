VisibleCloset::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Specifies the header that your server uses for sending files
  config.action_dispatch.x_sendfile_header = "X-Sendfile"

  # For nginx:
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'

  # If you have no front-end server that supports something like X-Sendfile,
  # just comment this out and Rails will serve the files

  # See everything in the log (default is :info)
  # config.log_level = :debug

  # Use a different logger for distributed setups
  # config.logger = SyslogLogger.new

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Disable Rails's static asset server
  # In production, Apache or nginx will already do this
  config.serve_static_assets = false

  # Enable serving of images, stylesheets, and javascripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  # Customizations for The Visible Closet
  config.our_box_product_id = 10
  config.our_box_product_id_gf = 1
  config.your_box_product_id = 11
  config.your_box_product_id_gf = 3
  config.our_box_inventorying_product_id = 12
  config.our_box_inventorying_product_id_gf = 5
  config.your_box_inventorying_product_id = 13
  config.your_box_inventorying_product_id_gf = 6
  config.return_box_product_id = 7
  config.item_donation_product_id = 8
  config.item_mailing_product_id = 9
  config.stocking_fee_product_id = 14
  config.stocking_fee_waiver_product_id = 15
  config.furniture_storage_product_id = 16

  config.fedex_vc_address_id = 6
  
  config.furniture_stock_photo_id = 80

  config.after_initialize do    
    ::CIM_GATEWAY = ActiveMerchant::Billing::AuthorizeNetCimGateway.new(
      :login => "5Fe5e8GF6z7H", # "API Login ID"
      :password => "83zM4HAnrm84D4pB" # "Transaction Key"
    )
    
    ::PURCHASE_GATEWAY = ActiveMerchant::Billing::Base.gateway(:authorize_net).new(
      :login => "5Fe5e8GF6z7H", # "API Login ID"
      :password => "83zM4HAnrm84D4pB" # "Transaction Key"
    )
  end
end
