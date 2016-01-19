shared_examples_for 'a belongs_to association' do |association, klass|

  let(:record) { klass.create }

  it 'sets the id when assigning a record' do
    subject.send("#{association}=", record)

    expect(subject.send("#{association}_id")).to eq(record.id)
  end

  it 'sets the record when assigning an id' do
    subject.send("#{association}_id=", record.id)

    expect(subject.send("#{association}")).to eq(record)
  end

end
