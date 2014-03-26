shared_examples_for 'a coercible string column' do |column|

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

  it 'leaves times alone' do
    time = Time.now
    subject.send(:"#{column}=", time)

    subject.send(column).should == time
  end

  it 'converts strings to times' do
    subject.send(:"#{column}=", "2010-10-01 12:15")

    subject.send(column).should == Time.new(2010, 10, 1, 12, 15)
  end

end


shared_examples_for 'a coercible boolean column' do |column|

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
