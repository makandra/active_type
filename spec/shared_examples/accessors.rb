shared_examples_for "ActiveRecord-like accessors" do |attributes|

  it 'allows to read and write' do
    attributes.each do |key, value|
      subject.send("#{key}=", value)
      expect(subject.send(key)).to eq(value)
    end
  end

  it 'allows to read via []' do
    attributes.each do |key, value|
      subject.send("#{key}=", value)
      expect(subject[key]).to eq(value)
    end
  end

  it 'allows to write via []=' do
    attributes.each do |key, value|
      subject[key] = value
      expect(subject.send(key)).to eq(value)
    end
  end

  it 'allows reading via read_attribute' do
    attributes.each do |key, value|
      subject.send("#{key}=", value)
      expect(subject.send(:read_attribute, key)).to eq(value)
    end
  end

  if ActiveRecord::VERSION::STRING >= '4.2.0'
    # Rails 4.2 introduced this internal reader method for performance reasons.
    # https://github.com/rails/rails/commit/08576b94ad4f19dfc368619d7751e211d23dcad8
    # It is called by `read_attribute` and other ActiveRecord methods, so we test its behavior explicitly.
    it 'allows reading via _read_attribute' do
      attributes.each do |key, value|
        subject.send("#{key}=", value)
        expect(subject._read_attribute(key)).to eq(value)
      end
    end
  end

  it 'allows writing via write_attribute' do
    attributes.each do |key, value|
      subject.send(:write_attribute, key, value)
      expect(subject.send(key)).to eq(value)
    end
  end

  if ActiveRecord::VERSION::STRING >= '5.2.0'
    # Rails 5.2 introduced this internal writer method for performance reasons.
    # https://github.com/rails/rails/commit/c879649a733d982fba9e70f5a280d13636b67c37
    # It is called by `write_attribute` and other ActiveRecord methods, so we test its behavior explicitly.
    it 'allows writing via _write_attribute' do
      attributes.each do |key, value|
        subject._write_attribute(key, value)
        expect(subject.send(key)).to eq(value)
      end
    end
  end

end
