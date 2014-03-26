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

  if ActiveRecord::VERSION::MAJOR >= 4

    it 'raises on unpermitted parameters' do
      params = ProtectedParams.new(attributes)
      expect { subject.new(params) }.to raise_error(ActiveModel::ForbiddenAttributesError)
    end

    it 'accepts permitted parameters' do
      params = ProtectedParams.new(attributes)
      params.permit!
      expect { subject.new(params) }.to_not raise_error
    end

  end

end
