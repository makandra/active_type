# encoding: utf-8

require File.expand_path('../boot', __FILE__)

require 'rails/all'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

module SpecApp
  class Application < Rails::Application
    config.encoding = "utf-8"

    config.cache_classes = true
    config.whiny_nils = true

    config.consider_all_requests_local       = true
    config.action_controller.perform_caching = false

    config.action_dispatch.show_exceptions = false

    config.action_controller.allow_forgery_protection    = false

    config.action_mailer.delivery_method = :test

    config.active_support.deprecation = :stderr

    config.root = File.expand_path('../..', __FILE__)

    # railties.plugins << Rails::Plugin.new(File.expand_path('../../../../..', __FILE__))
  end
end
