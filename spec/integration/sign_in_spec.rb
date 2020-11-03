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
      expect(subject).not_to be_valid
    end

    it 'has errors' do
      subject.valid?
      expect(subject.errors[:email]).to eq(["can't be blank"])
      expect(subject.errors[:password]).to eq(["can't be blank"])
    end

    it 'does not save' do
      expect(subject.save).to be_falsey
    end

    it 'does not set the session' do
      expect(subject).not_to receive :set_session
      subject.save
    end

  end

  describe 'with invalid credentials' do

    before do
      subject.email = "email"
      subject.password = "incorrect password"
    end

    it 'is invalid' do
      expect(subject).not_to be_valid
    end

    it 'has errors' do
      subject.valid?
      expect(subject.errors[:password]).to eq(["is not correct"])
    end

    it 'does not save' do
      expect(subject.save).to be_falsey
    end

    it 'does not set the session' do
      expect(subject).not_to receive :set_session
      subject.save
    end

    context 'before save' do
      it_should_behave_like 'an instance supporting serialization'
    end

  end

  describe 'with valid credentials' do

    before do
      subject.email = "email"
      subject.password = "correct password"
    end

    it 'is invalid' do
      expect(subject).to be_valid
    end

    it 'does save' do
      expect(subject.save).to eq(true)
    end

    it 'sets the session' do
      expect(subject).to receive :set_session
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
