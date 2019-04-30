shared_examples_for "a class supporting dirty tracking for virtual attributes" do |klass|

  subject do
    Class.new(klass) do
      attribute :virtual_attribute
    end.new
  end

  describe '#virtual_attribute_was' do

    it 'always returns nil, since there can be no previously saved value' do
      expect(subject.virtual_attribute_was).to be_nil
    end

  end

  describe '#virtual_attribute_changed?' do

    it 'returns true if the attribute is not nil' do
      subject.virtual_attribute = 'foo'
      expect(subject.virtual_attribute_changed?).to eq(true)
    end

    it 'returns false if the attribute is nil' do
      subject.virtual_attribute = nil
      expect(subject.virtual_attribute_changed?).to be_falsey
    end

  end

  describe '#virtual_attribute_will_change!' do

    it 'is implemented for compatibility with ActiveModel::Dirty, but does nothing' do
      expect(subject).to respond_to(:virtual_attribute_will_change!)
      expect { subject.virtual_attribute_will_change! }.to_not raise_error
    end

  end

  describe '#changed?' do

    it 'returns true if any of the attribute is not nil' do
      subject.virtual_attribute = 'foo'
      expect(subject.changed?).to eq(true)
    end

    it 'returns false if all attributes are nil' do
      subject.virtual_attribute = nil
      expect(subject.changed?).to eq(false)
    end

  end

  describe '#changes?' do

    it 'returns hash of changes if any atribute is not nil' do
      subject.virtual_attribute = 'foo'
      expect(subject.changes).to eq(
        "virtual_attribute" => [nil, 'foo']
      )
    end

    it 'returns empty hash if all attributes are nil' do
      subject.virtual_attribute = nil
      expect(subject.changes).to eq({})
    end
  end
end
