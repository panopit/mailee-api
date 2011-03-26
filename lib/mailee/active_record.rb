# coding: utf-8
# The Sync module is responsible for keeping a model syncd with Mailee.
# It's behaviour is still too rails-twooish. But soon I'll make it more
# treeish using Railties and stuff. But it works.
#
# All you need in your model are two fields, one for the email and one
# for the optin, wich is by default called "news". The name field is
# optional but encouraged.
#
# USAGE
#
#   # Simple example
#   class Client < ActiveRecord::Base
#     sync_with_mailee
#   end
#
#   # Super hyper brainfuck complex example
#   class Client < ActiveRecord::Base
#     sync_with_mailee :email => :email_field, :name => :name_field, :news => :news_field
#   end

module Mailee
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
          self.sync_options = {:email => :email, :name => :name, :news => :news}.merge(options)
          unless self.column_names.include?(self.sync_options[:email].to_s)
            raise "Campo #{sync_options[:email]} não existe em #{new.class}."
          end
          unless self.column_names.include?(self.sync_options[:name].to_s)
            self.sync_options[:name] = nil
          end
          unless self.column_names.include?(self.sync_options[:news].to_s)
            self.sync_options[:news] = nil
          end
          if self.sync_options[:list]
            lists = List.find(:all).map(&:name)
            raise "A lista '#{self.sync_options[:list]}' não existe no Mailee.me." unless lists.include?(self.sync_options[:list])
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
          contact.put(:subscribe, :list => sync_options[:list]) if sync_options[:list]
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
              contact.put(:subscribe, :list => sync_options[:list]) if sync_options[:list]
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

        # Sends all items from the model to Mailee.
        # Allows passing a datetime to send only contacts updated after.
        # Also allows the use of a block, wich will receive the record of
        # the model and the record from Mailee:
        #
        #   Contact.send_all_to_mailee{|i,im| im.address = i.endereco; im.save }
        #
        # IMPORTANT:
        # This method only _sends_ contacts. It does not receives 'em.
        # If you need to receive contacts, for now the best way is to export in
        # Mailee's web interface and import in your app.
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
