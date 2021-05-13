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

  describe '.model_name' do

    context 'when extending an ActiveRecord' do
      let(:base_model_name) { STISpec::Child.model_name }
      let(:extended_model_name) { STISpec::ExtendedChild.model_name }

      it 'has the same model name as the active record base class' do
        expect(extended_model_name.singular).to eq(base_model_name.singular)
        expect(extended_model_name.plural).to eq(base_model_name.plural)

        expect(extended_model_name.collection).to eq(base_model_name.collection)
        expect(extended_model_name.element).to eq(base_model_name.element)
        expect(extended_model_name.human).to eq(base_model_name.human)
      end

      it 'has the same route keys as the active record base class' do
        expect(extended_model_name.route_key).to eq(base_model_name.route_key)
        expect(extended_model_name.singular_route_key).to eq(base_model_name.singular_route_key)
      end

      it 'has the same param key as the active record base class' do
        expect(extended_model_name.param_key).to eq(base_model_name.param_key)
      end

      it 'has a different i18n_key than the active record base class' do
        expect(extended_model_name.i18n_key).not_to eq(base_model_name.i18n_key)
        expect(extended_model_name.i18n_key).to eq(:'sti_spec/extended_child')
      end
    end

    context 'when extending an already extended ActiveRecord' do
      let(:base_model_name) { STISpec::Child.model_name }
      let(:extended_model_name) { STISpec::ExtendedChild.model_name }
      let(:extended_extended_model_name) { STISpec::ExtendedExtendedChild.model_name }

      it 'has still the same model name as the active record base class' do
        expect(extended_extended_model_name.singular).to eq(base_model_name.singular)
        expect(extended_extended_model_name.plural).to eq(base_model_name.plural)

        expect(extended_extended_model_name.collection).to eq(base_model_name.collection)
        expect(extended_extended_model_name.element).to eq(base_model_name.element)
        expect(extended_extended_model_name.human).to eq(base_model_name.human)
      end

      it 'has still the same route keys as the active record base class' do
        expect(extended_extended_model_name.route_key).to eq(base_model_name.route_key)
        expect(extended_extended_model_name.singular_route_key).to eq(base_model_name.singular_route_key)
      end

      it 'has still the same param key as the active record base class' do
        expect(extended_extended_model_name.param_key).to eq(base_model_name.param_key)
      end

      it 'has a different i18n_key than the active record base and the extended class' do
        expect(extended_extended_model_name.i18n_key).not_to eq(base_model_name.i18n_key)
        expect(extended_extended_model_name.i18n_key).not_to eq(extended_model_name.i18n_key)
        expect(extended_extended_model_name.i18n_key).to eq(:'sti_spec/extended_extended_child')
      end

    end

  end

  describe 'i18n' do

    around :each do |test|
      begin
        orig_backend = I18n.backend
        I18n.backend = I18n::Backend::KeyValue.new({})
        test.run
      ensure
        I18n.backend = orig_backend
      end
    end

    describe 'translation of model name' do

      context 'when extending an ActiveRecord' do

        it 'has its own I18n key' do
          translations = {
            models: {
              'sti_spec/child': 'Child translation',
              'sti_spec/extended_child': 'ExtendedChild translation',
            },
          }

          I18n.backend.store_translations(:en, activerecord: translations)
          expect(STISpec::ExtendedChild.model_name.human).to eq('ExtendedChild translation')
        end

        it 'falls back to the I18n key of the base class if does not have its own I18n key' do
          translations = {
            models: {
              'sti_spec/child': 'Child translation',
            },
          }

          I18n.backend.store_translations(:en, activerecord: translations)
          expect(STISpec::ExtendedChild.model_name.human).to eq('Child translation')
        end

      end

      context 'when extending an already extended ActiveRecord' do

        it 'has its own I18n key' do
          translations = {
            models: {
              'sti_spec/child': 'Child translation',
              'sti_spec/extended_child': 'ExtendedChild translation',
              'sti_spec/extended_extended_child': 'ExtendedExtendedChild translation',
            },
          }

          I18n.backend.store_translations(:en, activerecord: translations)
          expect(STISpec::ExtendedExtendedChild.model_name.human).to eq('ExtendedExtendedChild translation')
        end

        it 'falls back to the I18n key of the extended class if does not have its own I18n key' do
          translations = {
            models: {
              'sti_spec/child': 'Child translation',
              'sti_spec/extended_child': 'ExtendedChild translation',
            },
          }

          I18n.backend.store_translations(:en, activerecord: translations)
          expect(STISpec::ExtendedExtendedChild.model_name.human).to eq('ExtendedChild translation')
        end

        it 'falls back to the I18n key of the base class if neither itself nor the extended class has its own I18n key' do
          translations = { models: { 'sti_spec/child': 'Child translation' } }

          I18n.backend.store_translations(:en, activerecord: translations)
          expect(STISpec::ExtendedExtendedChild.model_name.human).to eq('Child translation')
        end

      end

    end

    describe 'translation of attribute name' do

      context 'when extending an ActiveRecord' do

        it 'has its own I18n key' do
          translations = {
            attributes: {
              'sti_spec/child': { persisted_string: 'Child translation' },
              'sti_spec/extended_child': { persisted_string: 'ExtendedChild translation' },
            },
          }

          I18n.backend.store_translations(:en, activerecord: translations)
          expect(STISpec::ExtendedChild.human_attribute_name(:persisted_string)).to eq('ExtendedChild translation')
        end

        it 'falls back to the I18n key of the base class if does not have its own I18n key' do
          translations = { attributes: { 'sti_spec/child': { persisted_string: 'Child translation' } } }

          I18n.backend.store_translations(:en, activerecord: translations)
          expect(STISpec::ExtendedChild.human_attribute_name(:persisted_string)).to eq('Child translation')
        end

      end

      context 'when extending an already extended ActiveRecord' do

        it 'has its own I18n key' do
          translations = {
            attributes: {
              'sti_spec/child': { persisted_string: 'Child translation' },
              'sti_spec/extended_child': { persisted_string: 'ExtendedChild translation' },
              'sti_spec/extended_extended_child': { persisted_string: 'ExtendedExtendedChild translation' },
            },
          }

          I18n.backend.store_translations(:en, activerecord: translations)
          expect(STISpec::ExtendedExtendedChild.human_attribute_name(:persisted_string)).to eq('ExtendedExtendedChild translation')
        end

        it 'falls back to the I18n key of the extended class if does not have its own I18n key' do
          translations = {
            attributes: {
              'sti_spec/child': { persisted_string: 'Child translation' },
              'sti_spec/extended_child': { persisted_string: 'ExtendedChild translation' },
            },
          }

          I18n.backend.store_translations(:en, activerecord: translations)
          expect(STISpec::ExtendedExtendedChild.human_attribute_name(:persisted_string)).to eq('ExtendedChild translation')
        end

        it 'falls back to the I18n key of the base class if neither itself nor the extended class has its own I18n key' do
          translations = { attributes: { 'sti_spec/child': { persisted_string: 'Child translation' } } }

          I18n.backend.store_translations(:en, activerecord: translations)
          expect(STISpec::ExtendedExtendedChild.human_attribute_name(:persisted_string)).to eq('Child translation')
        end

      end

    end

  end

end
