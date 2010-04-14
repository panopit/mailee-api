module Mailee
  class Config < ActiveResource::Base
    # O self.site tem q ser configurado no environment!
  end
  class Contact < Config
    def self.find_by_internal_id iid
      find(:first, :params => {:internal_id => iid})
    end
  end
  class List < Config
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
          self.sync_options = {:email => :email, :name => :name}.merge(options) #options[:with] || :deleted_at
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
        Mailee::Contact.create :email => send(sync_options[:email]), :name => send(sync_options[:name]), :internal_id => id
      rescue
        logger.warn "MAILEE-API: Falhou ao criar o contato #{id} no Mailee"
      end

      def update_in_mailee
        #TODO
      rescue
        logger.warn "MAILEE-API: Falhou ao atualizar o contato #{id} no Mailee"
      end

      def destroy_in_mailee
        #TODO
      rescue
        logger.warn "MAILEE-API: Falhou ao atualizar o contato #{id} no Mailee"
      end

      module ClassMethods
        # Sincroniza todos os itens do modelo com Mailee.
        # Permite o uso de um bloco, que receberá o item do modelo e o item do Mailee associado a este.
        # Ex: Contact.send_all_to_mailee{|i,im| im.address = i.endereco; im.save }
        # Importante: este método apenas envia os contatos, mas não recebe.
        # Para receber contatos, o ideal é fazer uma exportação no Mailee e realizar uma importação deste arquivo CSV no seu sistema.
        
        def send_all_to_mailee
          for item in all
            begin
              contact = Mailee::Contact.find_by_internal_id item.id
              if contact
                contact.email = item.send(sync_options[:email])
                contact.name = item.send(sync_options[:name])
                contact.save
              else
                contact = Mailee::Contact.create :email => item.send(sync_options[:email]), :name => item.send(sync_options[:name]), :internal_id => item.id  
              end
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

