$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'sqlite3'
require 'active_record'
require 'mailee'
require 'spec'
require 'spec/autorun'

Spec::Runner.configure do |config|
  
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