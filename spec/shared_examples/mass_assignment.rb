shared_examples_for 'ActiveRecord-like mass assignment' do |attributes|

  it 'assigns all given attributes' do
    subject.attributes = attributes

    attributes.each do |key, value|
      expect(subject.send(key)).to eq(value)
    end
  end

  if ActiveRecord::VERSION::MAJOR >= 4

    it 'raises on unpermitted parameters' do
      params = ProtectedParams.new(attributes)
      expect { subject.attributes = params }.to raise_error(ActiveModel::ForbiddenAttributesError)
    end

    it 'accepts permitted parameters' do
      params = ProtectedParams.new(attributes)
      params.permit!
      expect { subject.attributes = params }.to_not raise_error
    end

  end

end
