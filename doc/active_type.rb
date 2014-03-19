# Gibt leider schon ein activeobject gem :(
# Ich könnt machen:
# - active_object
# - active_anything
# - active_foo
# An "active*" gefällt mir übrigens, dass es sich so anfühlt
# wie ein leichtgewichtiges Update zu ActiveRecord



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

class User < ActiveType::Record

# Ist wie ActiveRecord::Base + noch ein paar Goodies
# wie z. B. virtuelle Attribute mit Coercion




describe ActiveType::Record do

  it 'should be like ActiveRecord::Base'
  it_should_behave_like 'virtual attributes with coercion and dirty tracking'

end


describe ActiveType::Object do

  it_should_behave_like 'constructor to set attributes'
  it_should_behave_like 'mass assignment with strong parameters'
  it_should_behave_like 'virtual attributes with coercion and dirty tracking'
  it_should_behave_like 'validatations with callback'
  it_should_behave_like 'save with callbacks'
  it_should_behave_like 'batch updates of nested records'
  it_should_behave_like 'belongs_to association where the foreign key sets the instance and vice versa'  

end


describe ActiveType::Role do

  it 'should preserve original model name'
  it 'should work with STI'
  
  it_should_behave_like 'constructor to set attributes'
  it_should_behave_like 'mass assignment with strong parameters'
  it_should_behave_like 'virtual attributes with coercion and dirty tracking'
  it_should_behave_like 'validatations with callback'
  it_should_behave_like 'save with callbacks'
  it_should_behave_like 'batch updates of nested records'
  it_should_behave_like 'belongs_to association where the foreign key sets the instance and vice versa'

  it 'should extend ActiveRecord objects'
  
  it 'should extend ActiveType objects'
  
  it 'should not extend other objects'
  
end



