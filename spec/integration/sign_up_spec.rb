require 'spec_helper'

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

    subject.should be_valid
  end

end


describe SignUpSpec::SignUp do

  it 'is invalid without an email' do
    subject.password = "password"
    subject.terms = true

    subject.should_not be_valid
    subject.errors['email'].should == ["can't be blank"]
  end

  it 'is invalid without accepted terms' do
    subject.email = "email"
    subject.password = "password"

    subject.should_not be_valid
    subject.errors['terms'].should == ["must be accepted"]
  end

  context 'with invalid data' do

    it 'does not save' do
      subject.save.should be_false
    end

    it 'does not send an email' do
      subject.should_not_receive :send_welcome_email
      subject.save
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
      subject.save.should be_true
    end

    it 'sends the email' do
      subject.should_receive :send_welcome_email

      subject.save
    end

  end


end
