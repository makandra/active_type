module ActiveType
  module Development
    extend self

    def drop_all_tables
      connection = ::ActiveRecord::Base.connection
      connection.tables.each do |table|
        connection.drop_table table
      end
    end

    def migrate_test_database
      print "\033[30m" # dark gray text
      drop_all_tables
      ::ActiveRecord::Migrator.migrate("#{Rails.root}/db/migrate")
      print "\033[0m"
    end

    def selects_star_with_conditions_pattern(table, conditions)
      table = Regexp.quote(table)
      conditions = Regexp.quote(conditions) unless conditions.is_a?(Regexp)
      /\ASELECT (`#{table}`\.)?\* FROM `#{table}`\s+WHERE \(?#{conditions}\)?\s*\z/
    end

  end
end

