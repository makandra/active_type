require 'spec_helper'

class User < ActiveRecord::Base
end

class Foo < ActiveType::Record[User]
  def new
    allocate
  end
end

describe 'ActiveType::Record' do
  it 'setup the virtual_attributes instance variable lazy' do
    foo = Foo.new
    expect(foo.virtual_attributes).to eq({})
  end

  it 'setup the virtual_attributes_cache instance variable lazy' do
    foo = Foo.new
    expect(foo.virtual_attributes_cache).to eq({})
  end
end

