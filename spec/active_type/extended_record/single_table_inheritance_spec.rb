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

  class ExtendedParent < ActiveType::Record[Parent]
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

    it 'it does not require an STI type condition' do
      expect(STISpec::ExtendedParent.descends_from_active_record?).to eq(true)
      expect(STISpec::ExtendedChild.descends_from_active_record?).to eq(false)
      expect(STISpec::ExtendedExtendedChild.descends_from_active_record?).to eq(false)
    end

    it 'can save and load the active type record' do

      should_save_and_load(STISpec::ExtendedChild, STISpec::ExtendedChild)
    end

    it 'can save as base child record and load as extended child record' do
      should_save_and_load(STISpec::Child, STISpec::ExtendedChild)
    end

    it 'will instantiate STI child records as the extended parent' do
      # We have a weird situation here:
      # Imagine this code
      #
      # class Parent < ActiveRecord::Base; end
      # class ExtendedParent < ActiveType::Record[Parent]; end   # ActiveType form model
      # class Child < Parent; end                                # STI inheritance
      #
      # Child.create!
      # ExtendedParent.last # is this of type Child or of type ExtendedParent?
      #
      # We cannot instantiate the child to inherit ExtendedParent and Child at the same time.
      # We opt to instantiate as ExtendedParent in this case (since you could get the other
      # behaviour by using `Parent.last`).
      #
      # We could alternatively raise an error, or at least print a warning.
      should_save_and_load(STISpec::Child, STISpec::ExtendedParent)
    end

    it 'will convert child records when loaded via the non-extended parent' do
      # this is standard ActiveRecord behaviour
      record = STISpec::Child.create!(persisted_string: 'string')
      expect(STISpec::Parent.find(record.id)).to be_a(STISpec::Child)
    end

    it 'can save as extended child record and load as base record' do
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
