require 'rails/generators'
require 'rails/generators/actions'

# = Mailee Railtie
#
# Creates a new railtie in order to add the mailee_rails:setup generator.
class MaileeRails < Rails::Railtie

  # Creates the mailee:rails:setup generator. This generator creates an initializer
  # called "mailee.rb" by asking the user his api URL, and defining it to
  # Mailee::Config.site attribute wich makes all that ActiveResource stuff works.
  class Setup < Rails::Generators::Base
    include Rails::Generators::Actions
    def create
      puts "Please enter your api URL:"
      attempts = 0
      url = readline.gsub(/\n/,'').gsub(/\s+/, '')
      while url !~ /^http:\/\/api\.[a-f0-9]{13}\.[a-z\-]+?\.mailee\.me$/
        attempts += 1
        if attempts < 3
          puts "Invalid URL. Please try again:"
          url = readline.gsub(/\n/,'').gsub(/\s+/, '')
        else
          puts "I think need support. Please talk to us on IRC (#maileeme) or send an email to suporte@mailee.me"
          exit
        end
      end
      initializer("mailee.rb") do
        "Mailee::Config.site = '#{url}'"
      end
      puts "*** Keep your key top secret, ok?"
      puts "*** If anything goes wrong, reach us on IRC (#mailee) or by email on suporte@mailee.me"
      puts "*** Thanks for using Mailee.me"
    end
  end
end