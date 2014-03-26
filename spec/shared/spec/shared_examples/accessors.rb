shared_examples_for "ActiveRecord-like accessors" do |attributes|

  it 'allows to read and write' do
    attributes.each do |key, value|
      subject.send("#{key}=", value)
      subject.send(key).should == value
    end
  end

  it 'allows to read via []' do
    attributes.each do |key, value|
      subject.send("#{key}=", value)
      subject[key].should == value
    end
  end

  it 'allows to write via []=' do
    attributes.each do |key, value|
      subject[key] = value
      subject.send(key).should == value
    end
  end

end
