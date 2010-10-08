$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'action_mailer'
require 'mailee'
require 'spec'
require 'spec/autorun'

Spec::Runner.configure do |config|
end

class Foo < ActionMailer::Base

  send_with_mailee

  default :from => "Maiz <maiz@softa.com.br>"

  def bar(date=Time.now)
    @greeting = "Hi"
    mail :date => date, :to => ["juanmaiz@gmail.com"]
  end
  
end