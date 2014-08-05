shared_examples_for "a class accepting attribute defaults" do |klass|

  subject do
    Class.new(klass) do
      attribute :static_string, :string, :default => "static string"
      attribute :dynamic_string, :string, :default => proc { "dynamic string" }
      attribute :referential_string, :string, :default => proc { value }
      attribute :number, :integer, :default => "10"
      attribute :computed, :default => proc { compute }

      def value
        "value"
      end

    end.new
  end

  it 'can have static defaults' do
    subject.static_string.should == "static string"
  end

  it 'can have dynamic defaults' do
    subject.dynamic_string.should == "dynamic string"
  end

  it 'can have defaults refering to instance methods' do
    subject.referential_string.should == "value"
  end

  it 'typecasts defaults' do
    subject.number.should == 10
  end

  it 'computes defaults lazily' do
    subject.should_receive(:compute).and_return("computed")
    subject.computed.should == "computed"
  end

  it 'does not compute defaults more than once' do
    subject.should_receive(:compute).exactly(:once).and_return(nil)
    subject.computed
    subject.computed
  end

  it 'does not compute defaults when overriden' do
    subject.computed = 'not computed'
    subject.computed.should == 'not computed'
  end

  it 'does not use defaults when overriden' do
    subject.static_string = "my string"
    subject.static_string.should == "my string"
  end

  it 'does not use defaults when overriden with nil' do
    subject.static_string = nil
    subject.static_string.should == nil
  end

end
