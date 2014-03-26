class CreateTestTables < ActiveRecord::Migration

  def self.up

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

  end

  def self.down
    drop_table :users
  end

end
