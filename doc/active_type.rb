# Gibt leider schon ein activeobject gem :(
# Ich könnt machen:
# - active_object
# - active_anything
# - active_foo
# An "active*" gefällt mir übrigens, dass es sich so anfühlt
# wie ein leichtgewichtiges Update zu ActiveRecord


class User < ActiveType::Record

# Ist wie ActiveRecord::Base + noch ein paar Goodies
# wie z. B. virtuelle Attribute mit Coercion


class User::AsSignUp < ActiveType::Role[User]

# Ist wie ExtendedModel:
# - model_name wie User
# - sti_name wie User
#
# Added manche sachen wie:
# - Virtuelle Attribute mit Coercion (Virtus?) und Dirty-Tracking (??)
# - (Wenn ichs hinkriege): accepts_nested_attributes_for

class User::Report < ActiveType::Object

# Ist wie PlainModel:
# - Vgl. activerecord-tableless mit pretend_success
# - Hat save
# - Hat after/before save/validate-Callbacks wie in Rails 2
# - Hat Konstructor
# - Virtuelle Attribute mit Coercion (Virtus?) und Dirty-Tracking (??)
# - (Wenn ichs hinkriege): accepts_nested_attributes_for



describe ActiveObject::Object do

  it_should_behave_like 'constructor to set attributes'
  it_should_behave_like 'mass assignment with strong parameters'
  it_should_behave_like 'virtual attributes with coercion and dirty tracking'
  it_should_behave_like 'validatations with callback'
  it_should_behave_like 'save with callbacks'
  it_should_behave_like 'batch updates of nested records'

end


describe ActiveObject::Extension do

  it 'should extend ActiveRecord objects'
  
  it 'should extend ActiveObject objects'
  
  it 'should not extend other objects'
  
  it 'should preserve original model name'
  
  it 'should work with STI'
  
  it_should_behave_like 'constructor to set attributes'
  it_should_behave_like 'mass assignment with strong parameters'
  it_should_behave_like 'virtual attributes with coercion and dirty tracking'
  it_should_behave_like 'validatations with callback'
  it_should_behave_like 'save with callbacks'
  it_should_behave_like 'batch updates of nested records'

end



Strong Params?



