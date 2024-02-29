require 'active_support/testing/deprecation'

shared_examples_for "a class accepting attribute defaults" do |klass|
  include ActiveSupport::Testing::Deprecation

  subject do
    Class.new(klass) do
      attribute :static_string, :string, :default => "static string".freeze
      attribute :dynamic_string, :string, :default => proc { "dynamic string" }
      attribute :referential_string, :string, :default => proc { value }
      attribute :number, :integer, :default => "10".freeze
      attribute :computed, :default => proc { compute }

      def value
        "value"
      end

    end.new
  end

  it 'can have static defaults' do
    expect(subject.static_string).to eq("static string")
  end

  it 'can have dynamic defaults' do
    expect(subject.dynamic_string).to eq("dynamic string")
  end

  it 'can have defaults refering to instance methods' do
    expect(subject.referential_string).to eq("value")
  end

  it 'typecasts defaults' do
    expect(subject.number).to eq(10)
  end

  it 'computes defaults lazily' do
    expect(subject).to receive(:compute).and_return("computed")
    expect(subject.computed).to eq("computed")
  end

  it 'does not compute defaults more than once' do
    expect(subject).to receive(:compute).exactly(:once).and_return(nil)
    subject.computed
    subject.computed
  end

  it 'does not compute defaults when overriden' do
    subject.computed = 'not computed'
    expect(subject.computed).to eq('not computed')
  end

  it 'does not use defaults when overriden' do
    subject.static_string = "my string"
    expect(subject.static_string).to eq("my string")
  end

  it 'does not use defaults when overriden with nil' do
    subject.static_string = nil
    expect(subject.static_string).to eq(nil)
  end

  context 'deprecation for default option' do
    def deprecations_for
      _result, messages = collect_deprecations(ActiveType.deprecator) do
        yield
      end
      messages
    end

    it 'shows a deprecation warning when passing a non-frozen object' do
      messages = deprecations_for do
        Class.new(klass) do
          attribute :static_string, :string, default: "static string"
        end
      end

      expect(messages.size).to eq(1)
      expect(messages.first).to include('Passing a non-frozen object as a default is deprecated.')
    end

    it 'shows no deprecation warning when passing a frozen object' do
      messages = deprecations_for do
        Class.new(klass) do
          attribute :static_string, :string, default: "static string".freeze
        end
      end

      expect(messages.size).to eq(0)
    end

    it 'shows no deprecation warning when passing a proc' do
      messages = deprecations_for do
        Class.new(klass) do
          attribute :static_string, :string, default: -> { 'string' }
        end
      end

      expect(messages.size).to eq(0)
    end

    it 'reports the call location' do
      messages = deprecations_for do
        Class.new(klass) do
          attribute :static_string, :string, default: "static string"
        end
      end

      expect(messages.first).to include(__FILE__)
    end
  end
end
