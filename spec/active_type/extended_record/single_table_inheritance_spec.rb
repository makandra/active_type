require 'spec_helper'

module STISpec

  class Parent < ActiveRecord::Base
    self.table_name = 'sti_records'
  end

  class Child < Parent
  end

  class ExtendedChild < ActiveType::Record[Child]
  end

  class ExtendedExtendedChild < ActiveType::Record[ExtendedChild]
  end

end


describe 'ActiveType::Record[STIModel]' do

  describe 'persistence' do

    def should_save_and_load(save_as, load_as)
      record = save_as.new(:persisted_string => "string")
      expect(record.save).to eq(true)

      reloaded_child = load_as.find(record.id)
      expect(reloaded_child.persisted_string).to eq("string")
      expect(reloaded_child).to be_a(load_as)
    end

    it 'can save and load the active type record' do

      should_save_and_load(STISpec::ExtendedChild, STISpec::ExtendedChild)
    end

    it 'can save as base and load as active type record' do
      should_save_and_load(STISpec::Child, STISpec::ExtendedChild)
    end

    it 'can save as active type and load as base record' do
      should_save_and_load(STISpec::ExtendedChild, STISpec::Child)
    end

    it 'can load via the base class and convert to active type record' do
      record = STISpec::ExtendedChild.new(:persisted_string => "string")
      expect(record.save).to eq(true)

      reloaded_child = STISpec::Child.find(record.id).becomes(STISpec::ExtendedChild)
      expect(reloaded_child.persisted_string).to eq("string")
      expect(reloaded_child).to be_a(STISpec::ExtendedChild)
    end

    it 'can save classes further down the inheritance tree' do
      should_save_and_load(STISpec::ExtendedExtendedChild, STISpec::ExtendedExtendedChild)
    end

  end

end
