shared_examples_for "an instance supporting serialization" do
  it 'serializes correctly with to_yaml' do
    deserialized = YAML.load(subject.to_yaml)

    subject.attributes.each do |attr, value|
      expect(deserialized.send(attr)).to eq(value)
    end
  end
end
