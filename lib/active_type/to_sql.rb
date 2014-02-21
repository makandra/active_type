module ActiveType
  module ToSql

    def to_sql
      construct_finder_sql({})
    end

    if Util.activerecord2?
      ActiveRecord::Base.extend(self)
    end

  end
end
