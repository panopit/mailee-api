module Mailee
  # The Mailer class is responsible for making the mailee gem ActionMailer
  # compatible.
  #
  # USAGE:
  #
  #  If you want to use Mailee to send all your systems emails, simply
  #  configure the environment (dev or prod) like this:
  #
  #    config.action_mailer.delivery_method = Mailee::Mailer
  #
  #  But if you wanna send just a certain mailer with Mailee, add
  #  "send_with_mailee" on a per mailer basis
  #
  #    class Notifications < ActionMailer::Base
  #      send_with_mailee
  #    end
  #
  #  One important thing, is to add the sender's name to the default "from" in
  #  your mailer, this way:
  #
  #    default :from => "Your name <your@email.com.br>"
  #
  #  And don't forget to config your domain SPF!
  class Mailer
  
    def initialize config
    end
    def deliver! mail
      from_name = mail.header['from'].to_s.scan(/(.+?) <.+?>$/).to_s      
      message = Mailee::Message.create :title => mail.subject, :subject => mail.subject, :from_name => from_name, :from_email => mail.from.first, :emails => mail.to.join(' '), :html => mail.body.to_s
      result = message.ready(mail.date)
      mail.instance_eval{ self.class.send('attr_accessor', :mailee_message); self.mailee_message = result }
      self 
    end
  end

  module Send

    def self.included(base) # :nodoc:
      base.extend ClassMethods
    end

    module ClassMethods
      def send_with_mailee
        self.delivery_method = Mailee::Mailer
      end
    end

  end
end
ActionMailer::Base.send(:include, Mailee::Send)