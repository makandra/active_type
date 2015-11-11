begin
  # sqlite?
  ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')
rescue Gem::LoadError
  # pg?
  if ENV['BUNDLE_GEMFILE'] =~ /pg/
    if ENV['TRAVIS']
      ActiveRecord::Base.establish_connection(:adapter => 'postgresql', :database => 'active_type_test', :username => 'postgres')
    else
      ActiveRecord::Base.establish_connection(:adapter => 'postgresql', :database => 'active_type_test')
    end
  end
  # mysql2?
  if ENV['BUNDLE_GEMFILE'] =~ /mysql2/
    ActiveRecord::Base.establish_connection(:adapter => 'mysql2', :encoding => 'utf8', :database => 'active_type_test')
  end

  connection = ::ActiveRecord::Base.connection
  connection.tables.each do |table|
    connection.drop_table table
  end
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

  create_table :sti_records do |t|
    t.string :persisted_string
    t.string :type
  end

  create_table :other_records do |t|
    t.string :other_string
  end

end
