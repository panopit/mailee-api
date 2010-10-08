require 'active_resource'
module Mailee

  # The Config class is used to set your api url.
  # You can do it in your applications.rb or in a initializar.
  # It's simple:
  #
  #   Mailee::Config.site = "http://your.mailee.api.url"
  class Config < ActiveResource::Base
  end

  # The Contact class gives you default access to your contacts (all,
  # first, create, update, destroy) plus some facilities, like searching
  # contacts by email, keyword (a smart search), signature (name & email)
  # and internal id.
  #
  # Also, you can subscribe contacts to lists and unsubscribe. In Mailee
  # unsubscribing a contact is radical: it will be unsubscribed from ALL
  # lists FOREVER. House rules.
  #
  # If you use mailee gem to sync a model, it will always set the internal_id
  # to your "local" model id and then search based on it to update de remote
  # record.
  class Contact < Config
    def self.find_by_internal_id iid
      find(:first, :params => {:internal_id => iid})
    end
    def self.find_by_email email
      find(:first, :params => {:email => email})
    end
    def self.search keyword, page=1
      find(:all, :params => {:page => page, :by_keyword => keyword })
    end
    def unsubscribe(data={})
      #E.g. data --> {:reason => 'Trip to nowhere', :spam => false}
      put(:unsubscribe, :unsubscribe => {:reason => 'Motivo não especificado'}.merge(data))
    end
    def subscribe(list)
      put(:subscribe, :list => {:name => list})
    end
  end

  # The List class gives you default access to your lists (all, first, create, update, destroy)
  class List < Config
  end

  # The Template class gives you default access to your templates (all, first, create, update, destroy)
  class Template < Config
  end

  # The Quick class allows you to import contacts to mailee just like
  # in the interface
  #
  # USAGE:
  #
  #   # Emails only
  #   Mailee::Quick.import("witt@cambridge.uk dick@princeton.edu")
  #
  #   # Names and emails (needs line breaks)
  #   Mailee::Quick.import("witt@cambridge.uk, Wittgenstein\ndick@princeton.edu, Rorty")
  #   
  #   # Signatures (gmail style)
  #   Mailee::Quick.import('"Wittgenstein" <witt@cambridge.uk>,
  #                         "Rorty" <dick@princeton.edu.us>')
  class Quick < Config
    self.collection_name = "quick"
    def self.import contacts
      create :contacts => contacts
    end
  end

  # The Message class is where the fun happens.
  #
  # USAGE:
  #
  #   # Creating a message (still a draft):
  #   message = Mailee::Message.create :title => "TITLE", :subject => "SUBJ", :from_name => "NAME", :from_email => "your@email.com", :html => "<h1>Hello</h1>", :list_id => 666
  #   # Sending tests. 33, 44 and 55 are contact's ids.
  #   message.test([33,44,55]).should_not be nil
  #   # Sending the message now ...
  #   message.ready
  #   # ... or sending the message 10 days from now
  #   message.ready(10.days.from_now)
  class Message < Config
    def test contacts
      put(:test, :contacts => contacts)
    end
    def ready date=nil, hour=0
      if date && date.is_a?(Date) && date > Time.now
        put(:ready, :when => 'after', :after => {:date => date.strftime("%d/%m/%Y"), :hour => date.strftime('%H')})
      else
        put(:ready, :when => 'now')
      end
    end
  end
  
  # The Report class is still beta. It can return the results of a
  # message - total deliveries, accesses and returns. There are also
  # methods for getting accesses, unsubscribes and returns in "real time".
  class Report < Config
  end

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
      message.ready(mail.date)
      self 
    end
  end

  module Send

    def self.included(base) # :nodoc:
      base.extend ClassMethods
    end

    module ClassMethods
      def send_with_mailee
        puts "1"
        self.delivery_method = Mailee::Mailer
      end
    end

  end

  module Sync

    def self.included(base) # :nodoc:
      base.extend ClassMethods
    end

    module ClassMethods
      def sync_with_mailee(options = {})
        unless syncd? # don't let AR call this twice
          cattr_accessor :sync_options
          after_create :create_in_mailee
          after_update :update_in_mailee
          after_destroy :destroy_in_mailee
          self.sync_options = {:email => :email, :name => :name, :news => :news}.merge(options) #options[:with] || :deleted_at
          unless self.column_names.include?(self.sync_options[:email].to_s)
            raise "Campo #{sync_options[:email]} não existe em #{new.class}."
          end
          unless self.column_names.include?(self.sync_options[:name].to_s)
            self.sync_options[:name] = nil
          end
          unless self.column_names.include?(self.sync_options[:news].to_s)
            self.sync_options[:news] = nil
          end
        end
        include InstanceMethods
      end

      def syncd?
        self.included_modules.include?(InstanceMethods)
      end

    end

    module InstanceMethods #:nodoc:

      def self.included(base) # :nodoc:
        base.extend ClassMethods
      end
      
      def create_in_mailee
        return if( sync_options[:news] and ! send(sync_options[:news])) # Não cria se houver o campo booleano e ele for falso
        self.class.benchmark "Criando contato no Mailee" do
          contact = Mailee::Contact.new
          contact.internal_id = id
          contact.email = send(sync_options[:email])
          contact.name = send(sync_options[:name]) if sync_options[:name]
          contact.save
        end
      rescue
        logger.warn "MAILEE-API: Falhou ao criar o contato #{id} no Mailee"
      end

      def update_in_mailee
        self.class.benchmark "Atualizando contato no Mailee" do
          contact = Mailee::Contact.find_by_internal_id id
          if contact
            #Se o contato existe e o booleano foi desmarcado, realiza um UNSUBSCRIBE
            if sync_options[:news] and (! send(sync_options[:news]))
              unsubscribe_in_mailee(contact)
            else
              contact.email = send(sync_options[:email])
              contact.name = send(sync_options[:name]) if sync_options[:name]
              contact.save
            end
          else
            create_in_mailee # Se não achou o contato tem q inserir.
          end
        end
      rescue
        logger.warn "MAILEE-API: Falhou ao atualizar o contato #{id} no Mailee"
      end

      def destroy_in_mailee contact=nil
        self.class.benchmark "Excluindo contato no Mailee" do
          contact ||= Mailee::Contact.find_by_internal_id id
          contact.destroy
        end
      rescue
        logger.warn "MAILEE-API: Falhou ao excluir o contato #{id} no Mailee"
      end

      def unsubscribe_in_mailee contact=nil
        self.class.benchmark "Descadastrando contato no Mailee" do
          contact ||= Mailee::Contact.find_by_internal_id id
          contact.unsubscribe
        end
      rescue
        logger.warn "MAILEE-API: Falhou ao descadastrar o contato #{id} no Mailee"
      end
      
      module ClassMethods
        # Sincroniza todos os itens do modelo com Mailee.
        # Permite que se passe um datetime para enviar apenas os contatos atualizados depois desta data
        # Permite o uso de um bloco, que receberá o item do modelo e o item do Mailee associado a este.
        # Ex: Contact.send_all_to_mailee{|i,im| im.address = i.endereco; im.save }
        # Importante: este método apenas envia os contatos, mas não recebe.
        # Para receber contatos, o ideal é fazer uma exportação no Mailee e realizar uma importação deste arquivo CSV no seu sistema.
        
        def send_all_to_mailee(after=nil)
          items = after ? all(:conditions => ["updated_at >= ?", after]) : all
          for item in items
            begin
              contact = Mailee::Contact.find_by_internal_id item.id
              if contact and sync_options[:news] and ! item.send(sync_options[:news])
                contact.unsubscribe
                yield item, contact if block_given?
                next
              end
              unless contact
                next if sync_options[:news] and ! item.send(sync_options[:news])
                contact = Mailee::Contact.new
                contact.internal_id = item.id
              end
              contact.email = item.send(sync_options[:email])
              contact.name = item.send(sync_options[:name]) if sync_options[:name]
              contact.save
              yield item, contact if block_given?
            rescue
              logger.warn "MAILEE-API: Falhou ao enviar o contato #{id} ao Mailee"
            end
          end
        end
      end
    end
  end
end
ActiveRecord::Base.send(:include, Mailee::Sync) if defined?(ActiveRecord)
ActionMailer::Base.send(:include, Mailee::Send) if defined?(ActionMailer)