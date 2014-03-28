module TimeConversionSpec
  class Record < ActiveRecord::Base
  end
end

shared_examples_for 'a coercible string column' do |column|

  it 'is nil by default' do
    subject.send(column).should be_nil
  end

  it 'leaves strings alone' do
    subject.send(:"#{column}=", "string")

    subject.send(column).should == "string"
  end

  it 'does not convert blank' do
    subject.send(:"#{column}=", "")

    subject.send(column).should == ""
  end

end


shared_examples_for 'a coercible integer column' do |column|

  it 'is nil by default' do
    subject.send(column).should be_nil
  end

  it 'leaves integers alone' do
    subject.send(:"#{column}=", 10)

    subject.send(column).should == 10
  end

  it 'converts strings to integers' do
    subject.send(:"#{column}=", "10")

    subject.send(column).should == 10
  end

  it 'converts blank to nil' do
    subject.send(:"#{column}=", "")

    subject.send(column).should be_nil
  end

end


shared_examples_for 'a coercible date column' do |column|

  it 'is nil by default' do
    subject.send(column).should be_nil
  end

  it 'leaves dates alone' do
    date = Date.today
    subject.send(:"#{column}=", date)

    subject.send(column).should == date
  end

  it 'converts strings to dates' do
    subject.send(:"#{column}=", "2010-10-01")

    subject.send(column).should == Date.new(2010, 10, 1)
  end

  it 'converts blank to nil' do
    subject.send(:"#{column}=", "")

    subject.send(column).should be_nil
  end

end


shared_examples_for 'a coercible time column' do |column|

  around do |example|
    begin
      old_time_zone = Time.zone
      old_time_zone_aware_attributes = ActiveRecord::Base.time_zone_aware_attributes
      old_default_timezone = ActiveRecord::Base.default_timezone
      example.run
    ensure
      Time.zone = old_time_zone
      ActiveRecord::Base.time_zone_aware_attributes = old_time_zone_aware_attributes
      ActiveRecord::Base.default_timezone = old_default_timezone
      subject.class.reset_column_information
    end
  end

  def it_should_convert_like_active_record(column)
    time = "2010-10-01 12:15"
    TimeConversionSpec::Record.reset_column_information
    subject.class.reset_column_information

    comparison = TimeConversionSpec::Record.new
    subject.send(:"#{column}=", time)
    comparison.persisted_time = time

    result = subject.send(column)
    result.should == comparison.persisted_time
    result.zone.should == comparison.persisted_time.zone
  end


  it 'is nil by default' do
    subject.send(column).should be_nil
  end

  it 'leaves times alone' do
    time = Time.now
    subject.send(:"#{column}=", time)

    subject.send(column).should == time
  end

  it 'converts strings to times' do
    subject.send(:"#{column}=", "2010-10-01 12:15")

    subject.send(column).should == Time.new(2010, 10, 1, 12, 15)
  end

  it 'behaves consistently with ActiveRecord' do
    Time.zone = 'Hawaii'

    it_should_convert_like_active_record(column)
  end

  it 'behaves consistently with ActiveRecord if time_zone_aware_attributes is set' do
    Time.zone = 'Hawaii'
    ActiveRecord::Base.time_zone_aware_attributes = true

    it_should_convert_like_active_record(column)
  end

  it 'behaves consistently with ActiveRecord if default_timezone is :utc' do
    Time.zone = 'Hawaii'
    ActiveRecord::Base.default_timezone = :utc

    it_should_convert_like_active_record(column)
  end

  it 'behaves consistently with ActiveRecord if time_zone_aware_attributes is set, default_timezone is :utc' do
    Time.zone = 'Hawaii'
    ActiveRecord::Base.default_timezone = :utc
    ActiveRecord::Base.time_zone_aware_attributes = true

    it_should_convert_like_active_record(column)
  end

end


shared_examples_for 'a coercible boolean column' do |column|

  it 'is nil by default' do
    subject.send(column).should be_nil
  end

  it 'leaves booleans alone' do
    subject.send(:"#{column}=", true)

    subject.send(column).should == true
  end

  it 'converts 1 to true' do
    subject.send(:"#{column}=", "1")

    subject.send(column).should == true
  end

  it 'converts 0 to false' do
    subject.send(:"#{column}=", "0")

    subject.send(column).should == false
  end

  it 'converts "" to nil' do
    subject.send(:"#{column}=", "")

    subject.send(column).should be_nil
  end

  it 'converts "true" to true' do
    subject.send(:"#{column}=", "true")

    subject.send(column).should == true
  end

  it 'converts "false" to false' do
    subject.send(:"#{column}=", "false")

    subject.send(column).should == false
  end

end

shared_examples_for 'an untyped column' do |column|
  it 'is nil by default' do
    subject.send(column).should be_nil
  end

  it 'leaves strings alone' do
    subject.send(:"#{column}=", "string")

    subject.send(column).should == "string"
  end

  it 'leaves integers alone' do
    subject.send(:"#{column}=", 17)

    subject.send(column).should == 17
  end

  it 'leaves objects alone' do
    object = Object.new
    subject.send(:"#{column}=", object)

    subject.send(column).should == object
  end
end
