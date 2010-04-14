= Mailee - Email marketing para quem entende de tecnologia.
==============

== O problema

  Você está desenvolvendo um sistema (e-commerce, cms, erp...) e o seu cliente solicita a possibilidade de enviar e-mails promocionais, ou notícias, para diversos contatos. Por experiência própria, você sabe que enviar e-mails não é coisa para _scriptkiddies_, e que, de fato, não vale a pena o esforço de desenvolver todo um sistema que faça o envio, garanta a entrega, analise os retornos e também apresente resultados de tudo isso. O problema é que os sistemas que você conhece não permitem uma integração fácil e rápida com seus sistemas em Rails...

== A solução

  Este plugin tem como objetivo manter os contatos da sua aplicação sincronizados com os contatos do Mailee (www.mailee.me) sem muito esforço. De fato, basta executar o método "sync_with_mailee" no seu modelo (clientes, contatos, pessoas...) que este irá automaticamente realizar as tarefas de inserir, atualizar, excluir e descadastrar via REST. No Mailee, seu cliente poderá então montar as mensagens e enviar para os contatos.

== Instalação

 * Execute o seguinte comando em sua aplicação Rails:
 > script/plugin install git@github.com:softa/mailee-api.git
 * Adicione a seguinte linha de configuração em sua aplicação:
 Mailee::Config.site = 'http://api.chave.subdominio.wizee.net'
 O site você descobre entrando no Mailee e indo em Configurações > Integração > REST
 
 Pronto!
 
== Uso

  * Na mão (console)
  Você pode usar a api do maile "na mão". Basta abrir o console e usar:
  > ruby script/console
  >> Contact.find(:all)
  >> Contact.find(:first)
  >> Contact.create(:name => 'Bertrand Russell', :email => 'russell@cambridge.edu.uk')
  Mais exemplos você encontra(rá) na (futura) documentação da API.
  * Com modelos (ActiveRecord)
  Este plugin é feito para manter um modelo AciveRecord sincronizado com os contatos do Mailee. Para fazer isto, basta colocar o método "sync_with_mailee" em seu modelo. Se o seu modelo se chama "Contact", por exemplo, o código seria este:
  =code
    class Contact < ActiveRecord::Base
      sync_with_mailee
    end
  A priori, o plugin espera que você tenha pelo menos um campo de email e pressupõe que o nome deste campo é "email". Se o campo da sua tabela não tem este nome, você pode fazer o seguinte:
  =code
    class Contact < ActiveRecord::Base
      sync_with_mailee :email => :my_email_column
    end
  Onde "my_email_column" é a coluna que guarda o e-mail na sua tabela.
  O plugin também pode manter o nome do seu contato sincronizado, bastando para isto ter um campo "name" que será mapeado por padrão, mas que também pode ser sobrescrito:
  =code
    class Contact < ActiveRecord::Base
      sync_with_mailee :email => :my_email_column, :name => :my_name_column
    end  
  Por fim, o plugin permite que o cadastro no Mailee seja condicionado a um campo booleano (o padrão é "news"), que corresponde ao "opt-in" (a escolha de receber ou não mensagens) do seu contato. Ou seja, se o valor do campo for false, o plugin não cadastrará o contato no Mailee, e se o contato já estiver cadastrado e o valor deste campo mudar para falso, o contato será descadastrado e _não_ poderá ser mais cadastrado no Mailee (normas de privacidade). Para mudar o campo, basta:
  =code
    class Contact < ActiveRecord::Base
      sync_with_mailee :email => :my_email_column, :name => :my_name_column, :news => :do_you_really_accept_to_receive_our_newsletter
    end  
  * Tarefas (rake)
  Caso você já tenha itens cadastrados, é necessário adicionar estes contatos ao Mailee antes de mais nada. Para isso execute a tarefa rake:
  > rake mailee:send CLASS=Contact
  Onde "Contact" é o nome do seu modelo. Se você quer apenas enviar os contatos a partir de uma determinada data, você pode fazê-lo desta forma:
  > rake mailee:send CLASS=Contact AFTER=5.days.ago
  Neste caso, ele vai apenas sincronizar os contatos que foram atualizados (baseado no campo "updated_at") nos últimos 5 dias.  
  * Mas... como isso funciona, caso eu precise saber?
  O plugin utiliza a API REST do Mailee para enviar dados, por isto cuide bem da sua URL - se alguém descobrir isso pode ser ruim. Para saber qual o contato na sua aplicação o plugin utiliza um campo disponível no Mailee chamado "internal_id" o qual recebe o "id" da sua tabela na criação. Este id é usado nas atualizações, descadastros e exclusões, então tome (ou avise seu cliente para tomar!) cuidado ao editar este campo na interface do Mailee.

== Dúvidas?

  Qualquer dúvida, não hesite em falar conosco pelo e-mail suporte@mailee.me. 
