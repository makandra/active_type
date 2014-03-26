shared_examples_for 'a belongs_to association' do |association, klass|

  let(:record) { klass.create }

  it 'sets the id when assigning a record' do
    subject.send("#{association}=", record)

    subject.send("#{association}_id").should == record.id
  end

  it 'sets the record when assigning an id' do
    subject.send("#{association}_id=", record.id)

    subject.send("#{association}").should == record
  end

end
