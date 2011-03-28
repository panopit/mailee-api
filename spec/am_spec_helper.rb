$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rspec'
require 'action_mailer'
require 'mailee'

RSpec.configure do |config|
  Mailee::Config.site = "http://api.869a72b17b05a.mailee-api.mailee.me"
end

class FooMailer < ActionMailer::Base

  send_with_mailee

  default :from => "Maiz <maiz@softa.com.br>"

  def bar(date=Time.now)
    @greeting = "Hi"
    mail :date => date, :to => ["juanmaiz@gmail.com"]
  end
  
end