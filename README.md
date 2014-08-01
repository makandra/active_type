ActiveType [![Build Status](https://travis-ci.org/makandra/active_type.svg?branch=master)](https://travis-ci.org/makandra/active_type)
==========

Make any Ruby object quack like ActiveRecord
--------------------------------------------

ActiveType is our take on "presenter models" (or "form models") in Rails. We want to have controllers (and forms) talk to models that are either not backed by a database table, or have additional functionality that should not be shared to the rest of the application.

However, we do not want to lose ActiveRecord's amenities, like validations, callbacks, etc.

Examples for use cases are models to support sign in:

```ruby
class SignIn < ActiveType::Object

  # this is not backed by a db table
  
  attribute :username, :string
  attribute :password, :string

  validates :username, presence: true
  validates :password, presence: true
  
  # ...

end
```

Or models to support sign up:

```ruby
class User < ActiveRecord::Base
  # ...
end

class SignUp < ActiveType::Record[User]

  # this inherits from User

  validates :password, confirmation: true
  
  after_create :send_confirmation_email
  
  def send_confirmation_email
    # this should happen on sign-up, but not when creating a user in tests etc.
  end
  
  # ...
  
end
```

### ActiveType::Object


Inherit from `ActiveType::Object` if you want an `ActiveRecord`-kind class that is not backed by a database table.

You can define "columns" by saying `attribute`:

```ruby
class SignIn < ActiveType::Object
  
  attribute :email, :string
  attribute :date_of_birth, :date
  attribute :accepted_terms, :boolean
  attribute :account_type
  
end
```

These attributes can be assigned via constructor, mass-assignment, and are automatically typecast:

```ruby
sign_in = SignIn.new(date_of_birth: "1980-01-01", accepted_terms: "1", account_type: AccountType::Trial.new)
sign_in.date_of_birth.class # Date
sign_in.accepted_terms? # true
```

ActiveType knows all the types that are allowed in migrations (i.e. `:string`, `:integer`, `:float`, `:decimal`, `:datetime`, `:time`, `:date`, `:boolean`). You can also skip the type to have a virtual attribute without typecasting. 

**`ActiveType::Object` actually inherits from `ActiveRecord::Base`, but simply skips all database access, inspired by [ActiveRecord Tableless](https://github.com/softace/activerecord-tableless).**

This means your object has all usual `ActiveRecord::Base` methods. Some of those might not work properly, however. What does work:

- validations
- callbacks (use `before_save`, `after_save`, not `before_create`, or `before_update`)
- "saving" (returning `true` or `false`, without actually persisting)
- belongs_to (after saying `attribute :child_id, :integer`)


### ActiveType::Record

If you have a database backed record (that inherits from `ActiveRecord::Base`), but also want to declare virtual attributes, simply inherit from `ActiveType::Record`.

Virtual attributes will not be persisted.


### ActiveType::Record[BaseClass]

`ActiveType::Record[BaseClass]` is used to extend a given `BaseClass` (that itself has to be an `ActiveRecord` model) with additional functionality, that is not meant to be shared to the rest of the application.

You class will inherit from `BaseClass`. You can add additional methods, validations, callbacks, as well as use (virtual) attributes like an `ActiveType::Object`:

```ruby
class SignUp < ActiveType::Record[User]
  # ...
end
```

### Inheriting from ActiveType:: objects

If you want to inherit from an ActiveType class, simply do

```ruby
  class SignUp < ActiveType::Record[User]
    # ...
  end

  class SpecialSignUp < SignUp
    # ...
  end
```



Supported Rails versions
------------------------

ActiveType is tested against ActiveRecord 3.2, 4.0 and 4.1.

Later versions might work, earlier version will not.


Installation
------------

In your `Gemfile` say:

    gem 'active_type'

Now run `bundle install` and restart your server.


Development
-----------

- We run tests against several ActiveRecord versions.
- You can bundle all versions with `rake all:bundle`.
- You can run specs against all versions with `rake`.
- You can run specs against a single version with `VERSION=4.0 rake`.

If you would like to contribute:

- Fork the repository.
- Push your changes **with passing specs**.
- Send us a pull request.

I'm very eager to keep this gem leightweight and on topic. If you're unsure whether a change would make it into the gem, [talk to me beforehand](mailto:henning.koch@makandra.de).


Credits
-------

Tobias Kraze from [makandra](http://makandra.com/)

Henning Koch from [makandra](http://makandra.com/)


