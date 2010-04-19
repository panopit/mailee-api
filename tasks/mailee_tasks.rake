def obtain_class
  class_name = ENV['CLASS'] || ENV['class']
  raise "Deve especificar CLASS" unless class_name
  @klass = Object.const_get(class_name)
end

def obtain_after
  after = ENV['AFTER'] || ENV['after']
  @after = after ? eval(after) : nil
end

namespace :mailee do
  desc <<-DESC
Sincroniza os items da tabela CLASS com os contatos do Mailee.
Você pode também especificar o env AFTER para enviar apenas os contatos atualizados após uma data.
E.g. rake mailee:send CLASS=Contact AFTER=1.day.
  DESC
  task :send => :environment do
    klass = obtain_class
    after = obtain_after
    raise "A classe #{klass.name} deve ser sincronizada com o Mailee. Adicione o código 'sync_with_mailee'" if ! klass.syncd?
    print "Enviando\n"
    klass.send_all_to_mailee(after) do
      print "."
      STDOUT.flush
    end
  end
end
