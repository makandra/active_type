require 'spec_helper'

describe ActiveType::ToSql do

  describe '#to_sql' do

    it "should return the SQL the scope would produce" do
      scope = Forum.scoped(:conditions => { :name => 'Name' })
      scope.to_sql.should =~ ActiveType::Development.selects_star_with_conditions_pattern('forums', "`forums`.`name` = 'Name'")
    end

  end

end
