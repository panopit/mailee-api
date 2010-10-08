Mailee - Email marketing para quem entende de tecnologia.
==============

O problema
==

  Você está desenvolvendo um sistema (e-commerce, cms, erp...) e o seu cliente solicita a possibilidade de enviar e-mails promocionais, ou notícias, para diversos contatos. Por experiência própria, você sabe que enviar e-mails não é coisa para _scriptkiddies_, e que, de fato, não vale a pena o esforço de desenvolver todo um sistema que faça o envio, garanta a entrega, analise os retornos e também apresente resultados de tudo isso. O problema é que os sistemas que você conhece não permitem uma integração fácil e rápida com seus sistemas em Rails...

== A solução

  Esta gem tem como objetivo manter os contatos da sua aplicação sincronizados com os contatos do Mailee (www.mailee.me) sem muito esforço. De fato, basta executar o método "sync_with_mailee" no seu modelo (clientes, contatos, pessoas...) que este irá automaticamente realizar as tarefas de inserir, atualizar, excluir e descadastrar via REST. No Mailee, seu cliente poderá então montar as mensagens e enviar para os contatos.

== O que posso fazer com a gem?

 * Simplesmente utilizar as classes do Mailee para:
   * Criar, atualizar, buscar e excluir contatos.
   * Importar contatos com nome e email.
   * Criar, atualizar, buscar e excluir listas.
   * Criar, atualizar, buscar e excluir templates.
   * Criar rascunhos, enviar testes e enviar mensagens agora ou para uma data futura. O envio de mensagens permite enviar para uma lista, para um conjunto de emails, definindo o html na mão ou usando um template do Mailee.me e definindo áreas editáveis e de repetições.
   * Buscar datos dos relatórios.
 * Integrar com ActiveRecord (com ou sem Rails) e fazer um modelo sincronizar automaticamente com o Mailee.me.
 * Integrar com ActionMailer (com ou sem Rails) e fazer os mailers enviarem as mensagens pelo Mailee.me.

== Instalação

 * Adicione a seguinte linha ao seu Gemfile:
 > gem 'mailee'
 * E execute o bundle:
 > bundle install
 * Uma vez instalado, para configurar, execute:
 > rake mailee_rails:setup

  Este comando irá solicitar sua URL da API e criar um initializer com toda a configuração necessária.
  A URL da API você descobre entrando no Mailee e indo em Configurações > Integração > REST
 
  Pronto!

== Compatibilidade

  Rails 3. 'Nuff said. Se você precisa de suporte aoRails 2, baixe a versão 0.1.0, mas ela possui muito menos funcionalidades do que a versão atual.

== Uso

  * Na mão (console)

  Você pode usar a api do maile "na mão". Basta abrir o console e usar:
  > ruby script/console
  > include Mailee
  > Contact.find(:all)
  > Contact.find(:first)
  > Contact.search('russell')
  > Contact.find_by_internal_id(789)
  > Contact.find_by_email('russell@cambridge.edu.uk')
  > Contact.create(:name => 'Bertrand Russell', :email => 'russell@cambridge.edu.uk')
  > Contact.create(:email => 'ludwig@wittgenstein.edu.uk', :dynamic_attributes => {:influence => 'Frege'})
  > List.find(:all)
  > List.find(:first)
  > List.create(:name => 'My List')
  > Template.find(:all)
  > Template.find(:first)
  > Template.create(:title => 'My Template', :html => File.read('mytemplate.html'))
  > # Message with HTML and list
  > message = Message.create :title => "Title", :subject => "Subject", :from_name => "Rorty", :from_email => "rorty@princeton.us", :html => File.read('myhtml.html'), :list_id => 987
  > # Message with emails and template (with edits & repeats)
  > message = Message.create :title => "Title", :subject => "Subject", :from_name => "Rorty", :from_email => "rorty@princeton.us", :template_id => 765, :edits => {:greeting => 'Hi Davidson!'}, :repeats => {:news => ['A good news', 'A bad news'], :emails => 'davidson@some.com davidson@another.com'}
  > message.test([44,55,66])
  > message.ready # send it now
  > message.ready(10.days.from_now)

  * Com modelos (ActiveRecord)

  Esta gem é feita para manter um modelo AciveRecord sincronizado com os contatos do Mailee. Para fazer isto, basta colocar o método "sync_with_mailee" em seu modelo. Se o seu modelo se chama "Contact", por exemplo, o código seria este:
  =code
    class Contact < ActiveRecord::Base
      sync_with_mailee
    end
  A priori, a gem espera que você tenha pelo menos os campos de email e optins, e pressupõe que estes campos se chamem "email" e "news". Se os campos da sua tabela não tem estes nomes, você pode fazer o seguinte:
  =code
    class Contact < ActiveRecord::Base
      sync_with_mailee :email => :my_email_column, :news => :my_optin_column
    end
  Onde "my_email_column" é a coluna que guarda o e-mail na sua tabela e "my_optin_column" o booleano que guarda o optin.
  A gem também pode manter o nome do seu contato sincronizado, bastando para isto ter um campo "name" que será mapeado por padrão, mas que também pode ser sobrescrito:
  =code
    class Contact < ActiveRecord::Base
      sync_with_mailee :name => :my_name_column
    end  
  Se o valor do campo "news" (ou o que você utilizar para optin) for false, a gem não cadastrará o contato no Mailee. Se o contato já estiver cadastrado e o valor deste campo mudar para falso, o contato será descadastrado e _não_ poderá ser mais cadastrado no Mailee (normas de privacidade). Se ele estiver falso e mudar para verdadeiro, ele irá cadastrá-lo.

  * Com mailers (ActionMailer)
  
  Esta gem permite que você utilize o Mailee.me como meio de enviar suas mensagens sem precisar configurar um servidor smtp ou algo pareceido.
  
  Você pode optar por enviar todas as mensagens por ele, ou só as mensagens de determinados mailers. Para a configuração global, adicione a seguinte linha ao seu arquivo de ambiente (config/environments/production.rb ou development.rb):

  = code
    config.action_mailer.delivery_method = Mailee::Mailer

  Agora, se você quer enviar apenas mensagens de um certo mailer pelo Mailee, basta adicionar o método "send_with_mailee" em cada um:

  = code
    class Notifications < ActionMailer::Base
      send_with_mailee
      ...
    end
  
  É importante definir o from com o formato completo:

  = code
    class Notifications < ActionMailer::Base
      default :from => "Plato <plato@liceum.gr>
      ...
    end

  Ao enviar uma mensagem, você pode também optar por enviá-la agora ou no futuro:

  = code
    class Notifications < ActionMailer::Base
      def signup(client, date=Time.now)
        mail :date => date, :to => client.email
      end
      def feedback(client, date=Time.now)
        mail :date => date, :to => client.email
      end
    end
    ...
    Notifications.signup(client).deliver
    Notifications.feedback(client, 3.days.from_now).deliver

  Por fim, ao enviar uma mensagem, a gem adiciona um método que representa a mensagem no Mailee.me, veja:
  
  = code
    mail = Notifications.signup(client).deliver
    mail.mailee_message.id # Retorna o id
    mail.mailee_message.html # Retorna o html
    # e assim por diante...
  
  Isto é útil, pois você já pode monitorar os resultados com este id:

  = code
    mail = Notifications.signup(client).deliver
    Mailee::Report.find(mail.mailee_message.id)

  * Tarefas (rake)

  Caso você já tenha itens cadastrados, é necessário adicionar estes contatos ao Mailee antes de mais nada. Para isso execute a tarefa rake:
  > rake mailee:send CLASS=Contact
  Onde "Contact" é o nome do seu modelo. Se você quer apenas enviar os contatos a partir de uma determinada data, você pode fazê-lo desta forma:
  > rake mailee:send CLASS=Contact AFTER=5.days.ago
  Neste caso, ele vai apenas sincronizar os contatos que foram atualizados (baseado no campo "updated_at") nos últimos 5 dias.  

== Cuidado!

  A gem utiliza a API REST do Mailee para enviar dados, por isto cuide bem da sua URL - se alguém descobrir isso pode ser ruim. Para saber qual o contato na sua aplicação a gem utiliza um campo disponível no Mailee chamado "internal_id" o qual recebe o "id" da sua tabela na criação. Este id é usado nas atualizações, descadastros e exclusões, então tome (ou avise seu cliente para tomar!) cuidado ao editar este campo na interface do Mailee.

== Dúvidas?

  Qualquer dúvida, não hesite em falar conosco pelo e-mail suporte@mailee.me, pelo twitter @maileeme ou pelo IRC #maileeme. 
