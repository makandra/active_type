class User < ::ActiveRecord::Base
end

class Foo < ::ActiveType::Record[User]
  def new
    allocate
  end
end


shared_examples_for "ActiveRecord-like accessors" do |attributes|
  it 'setup the virtual_attributes instance variable lazy' do
    expect(Foo.new.virtual_attributes).to eq({})
  end

  it 'setup the virtual_attributes_cache instance variable lazy' do
    expect(Foo.new.virtual_attributes_cache).to eq({})
  end

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

end
