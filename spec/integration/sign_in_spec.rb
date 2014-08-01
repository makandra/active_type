# Usecase: implement a sign in form
# The sign in is not tied to a database record

require 'spec_helper'

module SignInSpec

  class SignIn < ActiveType::Object
    attribute :email, :string
    attribute :password, :string

    validates :email, :presence => true
    validates :password, :presence => true

    validate :if => :password do |sign_in|
      errors.add(:password, 'is not correct') unless sign_in.password == "correct password"
    end

    after_save :set_session

    def set_session
    end
  end

end

describe SignInSpec::SignIn do

  describe 'with missing credentials' do

    it 'is invalid' do
      subject.should_not be_valid
    end

    it 'has errors' do
      subject.valid?
      subject.errors[:email].should == ["can't be blank"]
      subject.errors[:password].should == ["can't be blank"]
    end

    it 'does not save' do
      subject.save.should be_false
    end

    it 'does not set the session' do
      subject.should_not_receive :set_session
      subject.save
    end

  end

  describe 'with invalid credentials' do

    before do
      subject.email = "email"
      subject.password = "incorrect password"
    end

    it 'is invalid' do
      subject.should_not be_valid
    end

    it 'has errors' do
      subject.valid?
      subject.errors[:password].should == ["is not correct"]
    end

    it 'does not save' do
      subject.save.should be_false
    end

    it 'does not set the session' do
      subject.should_not_receive :set_session
      subject.save
    end

  end

  describe 'with valid credentials' do

    before do
      subject.email = "email"
      subject.password = "correct password"
    end

    it 'is invalid' do
      subject.should be_valid
    end

    it 'does save' do
      subject.save.should be_true
    end

    it 'sets the session' do
      subject.should_receive :set_session
      subject.save
    end

  end

end
