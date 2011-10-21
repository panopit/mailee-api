# coding: utf-8

module Mailee

  # The Config class is used to set your api url.
  # You can do it in your applications.rb or in a initializer.
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
  #
  # Writable attributes:
  #   :name, :email, :internal_id, :sex, :birthday, :age, :phone, :mobile, :address, :notes, :photo, :company, :position
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
      print "Warning: Mailee::Contact.subscribe will be deprecated. Use Mailee::Contact.list_subscribe instead."
      put(:list_subscribe, :list => list)
    end
    def list_subscribe(list)
      put(:list_subscribe, :list => list)
    end
    def list_unsubscribe(list)
      put(:list_unsubscribe, :list => list)
    end
  end

  # The List class gives you default access to your lists (all, first, create, update, destroy)
  # Writable attributes:
  #   :name, :active, :company, :description, :address, :phone, :site
  class List < Config
  end

  # The Template class gives you default access to your templates (all, first, create, update, destroy)
  # Writable attributes:
  #   :title, :html
  class Template < Config
    def self.writable_attributes
      [:title, :html]
    end
    def thumb
      "http://assets.mailee.me/system/templates/#{id}/thumbs/thumb/#{id}.png"
    end
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
  #   message.test([33,44,55])
  #   # Sending the message now ...
  #   message.ready
  #   # ... or sending the message 10 days from now
  #   message.ready(10.days.from_now)
  #
  # Writeable attributes:
  #  :newsletter_id, :template_id, :list_id, :segment_id, :title, :subject, :from_name, :from_email, :reply_email, :html, :analytics
  class Message < Config
    def self.writeable_attributes
      [:newsletter_id, :template_id, :list_id, :contacts, :segment_id, :title, :subject, :from_name, :from_email, :reply_email, :html, :analytics]
    end
    def human_status
        ['','draft','sending','sent','generating'][status]
    end
    def signature
      "#{from_name} <#{from_email}>"
    end
    def thumb(size='thumb')
      "http://assets.mailee.me/system/messages/#{id}/thumbs/#{size}/#{id}.png"
    end
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

end
