shared_examples_for 'ActiveRecord-like mass assignment' do |attributes|

  it 'assigns all given attributes' do
    subject.attributes = attributes

    attributes.each do |key, value|
      subject.send(key).should == value
    end
  end

end
