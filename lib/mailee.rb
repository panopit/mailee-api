module Mailee
  class Config < ActiveResource::Base
    # O self.site tem q ser configurado no environment!
  end
  class Contact < Config
    def self.find_by_internal_id iid
      find(:first, :params => {:internal_id => iid})
    end
    def unsubscribe(data={})
      #E.g. data --> {:reason => 'Trip to nowhere', :spam => false}
      put(:unsubscribe, :unsubscribe => {:reason => 'Motivo não especificado'}.merge(data))
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

