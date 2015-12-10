shared_examples_for "a class supporting dirty tracking for virtual attributes" do |klass|

  context 'with no default value' do

    subject do
      Class.new(klass) do
        attribute :virtual_attribute
      end.new
    end

    describe '#virtual_attribute_was' do

      it 'always returns nil, since there can be no previously saved value' do
        subject.virtual_attribute_was.should be_nil
      end

    end

    describe '#virtual_attribute_changed?' do

      it 'returns true if the attribute is not nil' do
        subject.virtual_attribute = 'foo'
        subject.virtual_attribute_changed?.should be_true
      end

      it 'returns false if the attribute is nil' do
        subject.virtual_attribute = nil
        subject.virtual_attribute_changed?.should be_false
      end

    end

    describe '#virtual_attribute_will_change!' do

      it 'is implemented for compatibility with ActiveModel::Dirty, but does nothing' do
        subject.should respond_to(:virtual_attribute_will_change!)
        expect { subject.virtual_attribute_will_change! }.to_not raise_error
      end

    end

  end

  context 'with default value' do

    subject do
      Class.new(klass) do
        attribute :virtual_attribute, default: 'foo'
      end.new
    end

    describe '#virtual_attribute_was' do

      it 'returns default value' do
        subject.virtual_attribute_was.should eq 'foo'
      end

    end

    describe '#virtual_attribute_changed?' do

      it 'returns true if the attribute is not default' do
        subject.virtual_attribute = 'bar'
        subject.virtual_attribute_changed?.should be_true
      end

      it 'returns false if the attribute is default' do
        subject.virtual_attribute = 'foo'
        subject.virtual_attribute_changed?.should be_false
      end

    end

  end

end
