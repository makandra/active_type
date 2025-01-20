shared_examples_for 'a required belongs_to association' do |association, klass|

  let(:record) { klass.create }

  it 'sets the id when assigning a record' do
    subject.send("#{association}=", record)

    expect(subject.send("#{association}_id")).to eq(record.id)
  end

  it 'sets the record when assigning an id' do
    subject.send("#{association}_id=", record.id)

    expect(subject.send("#{association}")).to eq(record)
  end

  it 'is invalid if the associated record is not found' do
    subject.send("#{association}_id=", -1)

    expect(subject).to be_invalid
  end

  it 'is invalid if the assigned id is nil' do
    subject.send("#{association}_id=", nil)

    expect(subject).to be_invalid
  end
end

shared_examples_for 'an optional belongs_to association' do |association, klass|

  let(:record) { klass.create }

  it 'sets the id when assigning a record' do
    subject.send("#{association}=", record)

    expect(subject.send("#{association}_id")).to eq(record.id)
  end

  it 'sets the record when assigning an id' do
    subject.send("#{association}_id=", record.id)

    expect(subject.send("#{association}")).to eq(record)
  end

  it 'is valid even if the associated record is not found' do
    subject.send("#{association}_id=", -1)

    expect(subject).to be_valid
  end

  it 'is valid even if the assigned id is nil' do
    subject.send("#{association}_id=", nil)

    expect(subject).to be_valid
  end
end
