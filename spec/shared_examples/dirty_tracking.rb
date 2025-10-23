shared_examples_for "a class supporting dirty tracking for virtual attributes" do |klass|

  subject do
    Class.new(klass) do
      attribute :virtual_attribute
    end.new
  end

  describe '#virtual_attribute_was' do

    it 'returns value before changes were applied' do
      expect(subject.virtual_attribute_was).to be_nil
      subject.virtual_attribute = 'foo'
      subject.changes_applied
      expect(subject.virtual_attribute_was).to eq('foo')
    end

  end

  describe '#virtual_attribute_changed?' do

    it 'returns true if the attribute is different than previous one' do
      subject.virtual_attribute = 'foo'
      expect(subject.virtual_attribute_changed?).to eq(true)
    end

    it 'returns false if the attribute is the same as previous one' do
      subject.virtual_attribute = nil
      expect(subject.virtual_attribute_changed?).to be_falsey
    end

    it 'returns false after changes were applied' do
      subject.virtual_attribute = 'foo'
      subject.changes_applied
      expect(subject.virtual_attribute_changed?).to eq(false)
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

    context 'after applying changes' do
      it 'returns false' do
        subject.virtual_attribute = 'foo'
        subject.changes_applied
        expect(subject.changed?).to eq(false)
      end
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

    context 'after applying changes' do
      it 'returns empty hash' do
        subject.virtual_attribute = 'foo'
        subject.changes_applied
        expect(subject.changes).to eq({})
      end
    end

  end

  describe '#attribute_changed?' do
    it 'returns true if specified attribute is not nil' do
      subject.virtual_attribute = 'foo'
      expect(subject.attribute_changed?(:virtual_attribute)).to eq(true)
    end

    it 'returns false if specified attribute is nil' do
      subject.virtual_attribute = nil
      expect(subject.attribute_changed?(:virtual_attribute)).to eq(false)
    end

    context 'after applying changes' do
      it 'returns false' do
        subject.virtual_attribute = 'foo'
        subject.changes_applied
        expect(subject.attribute_changed?(:virtual_attribute)).to eq(false)
      end
    end

    it 'returns false if specified attribute does not exist' do
      expect(subject.attribute_changed?(:not_exist)).to eq(false)
    end
  end
end
