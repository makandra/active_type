# encoding: utf-8

$: << File.join(File.dirname(__FILE__), "/../../lib" )

module FakeRailsHelper
  def fake_rails
    require 'active_support'
    require 'active_record'
    eval <<-RUBY
      module ::Rails
        def self.env
          'test'
        end
      end
    RUBY
  end
end

RSpec.configure do |config|
  config.include FakeRailsHelper

  config.around(:example, type: :isolated) do |example|
    if defined?(ActiveType::Object) || defined?(ActiveType::Record)
      skip('can only run isolated')
    else
      example.run
    end
  end
end
