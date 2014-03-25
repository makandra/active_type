shared_examples_for 'ActiveRecord-like constructors' do |attributes|

  it 'return a new record' do
    subject.new.should be_new_record
  end

  it 'assigns given attributes' do
    record = subject.new(attributes)

    attributes.each do |key, value|
      record.send(key).should == value
    end
  end

end
