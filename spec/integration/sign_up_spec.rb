# Usecase: implement a sign up form
# The sign up is tied to a user model


require 'spec_helper'

ActiveRecord::Migration.class_eval do
  create_table :users do |t|
    t.string :email
    t.string :password
  end
end


module SignUpSpec

  class User < ActiveType::Record
    validates :email, :presence => true
    validates :password, :presence => true
  end


  class SignUp < ActiveType::Record[User]
    attribute :terms, :boolean

    validates :terms, :acceptance => {:allow_nil => false, :accept => true}

    after_create :send_welcome_email

    def send_welcome_email
    end
  end

end


describe SignUpSpec::User do

  it 'is valid without a password confirmation' do
    subject.email = "email"
    subject.password = "password"

    expect(subject).to be_valid
  end

end


describe SignUpSpec::SignUp do

  it 'is invalid without an email' do
    subject.password = "password"
    subject.terms = true

    expect(subject).not_to be_valid
    expect(subject.errors['email']).to eq(["can't be blank"])
  end

  it 'is invalid without accepted terms' do
    subject.email = "email"
    subject.password = "password"

    expect(subject).not_to be_valid
    expect(subject.errors['terms']).to eq(["must be accepted"])
  end

  context 'with invalid data' do

    it 'does not save' do
      expect(subject.save).to be_falsey
    end

    it 'does not send an email' do
      expect(subject).not_to receive :send_welcome_email
      subject.save
    end

    context 'before save' do
      it_should_behave_like 'an instance supporting serialization'
    end

  end

  context 'with valid data' do

    before do
      subject.email = "email"
      subject.password = "password"
      subject.terms = "1"
    end

    it 'does save' do
      subject.valid?
      expect(subject.save).to eq(true)
    end

    it 'sends the email' do
      expect(subject).to receive :send_welcome_email

      subject.save
    end

    context 'before save' do
      it_should_behave_like 'an instance supporting serialization'
    end

    context 'after save' do
      before { subject.save }
      it_should_behave_like 'an instance supporting serialization'
    end
  end


end
