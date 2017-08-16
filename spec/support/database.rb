require 'yaml'

# pg?
case ENV['BUNDLE_GEMFILE']
when /pg/
  if ENV['TRAVIS']
    ActiveRecord::Base.establish_connection(:adapter => 'postgresql', :database => 'active_type_test', :username => 'postgres')
  else
    ActiveRecord::Base.establish_connection(:adapter => 'postgresql', :database => 'active_type_test')
  end
# mysql2?
when /mysql2/
  config = { :adapter => 'mysql2', :encoding => 'utf8', :database => 'active_type_test' }
  custom_config_path = File.join(File.dirname(__FILE__), 'database.yml')
  if File.exists?(custom_config_path)
    custom_config = YAML.load_file(custom_config_path)
    config.merge!(custom_config)
  end
  ActiveRecord::Base.establish_connection(config)
else
  ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')
end


connection = ::ActiveRecord::Base.connection
tables = connection.respond_to?(:data_sources) ? connection.data_sources : connection.tables
tables.each do |table|
  connection.drop_table table
end

ActiveRecord::Migration.class_eval do

  create_table :records do |t|
    t.string :persisted_string
    t.integer :persisted_integer
    t.datetime :persisted_time
    t.date :persisted_date
    t.boolean :persisted_boolean
  end

  create_table :children do |t|
    t.integer :record_id
  end

  create_table :uuid_records, id: false do |t|
    t.string :id, primary_key: true
    t.string :persisted_string
  end

  create_table :sti_records do |t|
    t.string :persisted_string
    t.string :type
  end

  create_table :other_records do |t|
    t.string :other_string
  end

end
