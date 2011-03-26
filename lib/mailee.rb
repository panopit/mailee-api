require 'active_resource'

module Mailee; end

require 'mailee/active_resource'
require 'mailee/railties' if defined?(Rails)
require 'mailee/active_record' if defined?(ActiveRecord)
require 'mailee/action_mailer' if defined?(ActionMailer)
