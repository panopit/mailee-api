$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rspec'
require 'sqlite3'
require 'active_record'
require 'mailee'
require 'mailee/active_record'

RSpec.configure do |config|
  Mailee::Config.site = "http://api.869a72b17b05a.mailee-api.mailee.me"
end

db = "mailee-api-test.db"
File.unlink(db) rescue nil
SQLite3::Database.new(db)
ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => db)

ActiveRecord::Base.connection.create_table(:foos) do |t|
  t.column :email, :string
  t.column :name, :string
  t.column :news, :boolean
end

ActiveRecord::Base.connection.create_table(:bars) do |t|
  t.column :other_email, :string
  t.column :other_name, :string
  t.column :other_news, :boolean
end

class Foo < ActiveRecord::Base
  sync_with_mailee
end

class Bar < ActiveRecord::Base
  sync_with_mailee :email => :other_email, :name => :other_name, :news => :other_news
end

class FooList < ActiveRecord::Base
  set_table_name 'foos'
  @@moment = Time.now.strftime('%Y%m%d%H%M%S')
  @@list = Mailee::List.create :name => "Foo List #{@@moment}"
  sync_with_mailee :list => @@list.name
  def self.list
    @@list
  end
  def self.contacts_count
    Mailee::List.find(@@list.id).lists_contacts_count
  end
end
