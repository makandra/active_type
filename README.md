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

### Defaults ####

Attributes can have defaults. Those are lazily evaluated on the first read, if no value has been set.

```ruby
class SignIn < ActiveType::Object

  attribute :created_at, :datetime, default: proc { Time.now }

end
```

The proc is evaluated in the context of the object, so you can do

```ruby
class SignIn < ActiveType::Object

  attribute :email, :string
  attribute :nickname, :string, default: proc { email.split('@').first }

end

SignIn.new(email: "tobias@example.org").nickname # "tobias"
SignIn.new(email: "tobias@example.org", :nickname => "kratob").nickname # "kratob"
```

### Nested attributes

ActiveType supports its own variant of nested attributes via the `nests_one` /
`nests_many` macros. The intention is to be mostly compatible with
`ActiveRecord`'s `accepts_nested_attributes` functionality.

Assume you have a list of records, say representing holidays, and you want to support bulk
editing. Then you could do something like:

```ruby
class Holiday < ActiveRecord::Base
  validates :date, presence: true
end

class HolidaysForm < ActiveType::Object
  nests_many :holidays, reject_if: :all_blank, default: proc { Holiday.all }
end

class HolidaysController < ApplicationController
  def edit
    @holidays_form = HolidaysForm.new
  end

  def update
    @holidays_form = HolidaysForm.new(params[:holidays_form])
    if @holidays_form.save
      redirect_to root_url, notice: "Success!"
    else
      render :edit
    end
  end

end

# and in the view
<%= form_for @holidays_form, url: '/holidays', method: :put do |form| %>
  <ul>
    <%= form.fields_for :holidays do |holiday_form| %>
      <li><%= holiday_form.text_field :date %></li>
    <% end %>
  </ul>
<% end %>
```

- You have to say `nests_many :records`
- `records` will be validated and saved automatically
- The generated `.records_attributes =` expects parameters like `ActiveRecord`'s nested attributes, and works together with the `fields_for` helper:

  - either as a hash (where the keys are meaningless)

    ```ruby
    {
      '1' => { date: "new record's date" },
      '2' => { id: '3', date: "existing record's date" }
    }
    ```

  - or as an array

    ```ruby
    {
      [ date: "new record's date" ],
      [ id: '3', date: "existing record's date" ]
    }
    ```

To use it with single records, use `nests_one`. It works like `accept_nested_attributes` does for `has_one`. Use `.record_attributes =` to build the child record.

Supported options for `nests_many` / `nests_one` are:
- `build_scope`

  Used to build new records, for example:

  ```ruby
  nests_many :documents, build_scope: proc { Document.where(:state => "fresh") }
  ```

- `find_scope`

  Used to find existing records (in order to update them).

- `scope`

  Sets `find_scope` and `build_scope` together.

  If you don't supply a scope, `ActiveType` will guess from the association name, i.e. saying

  ```ruby
  nests_many :documents
  ```

  is the same as saying

  ```ruby
  nests_many :documents, scope: proc { Document }
  ```

  which is identical to

  ```ruby
  nests_many :documents, build_scope: proc { Document }, find_scope: proc { Document }
  ```

  All `...scope` options are evaled in the context of the record on first use, and cached. 

- `allow_destroy`

  Allow to destroy records if the attributes contain `_destroy => '1'`

- `reject_if`

  Pass either a proc of the form `proc { |attributes| ... }`, or a symbol indicating a method, or `:all_blank`.

  Will reject attributes for which the proc or the method returns true, or with only blank values (for `:all_blank`).

- `default`

  Initializes the association on first access with the given proc:

  ```ruby
  nests_many :documents, default: proc { Documents.all }
  ```


Casting records or relations
----------------------------

When working with ActiveType you will often find it useful to cast an ActiveRecord instance to its extended `ActiveType::Record` variant.

Use `ActiveType.cast` for this:

```
class User < ActiveRecord::Base
  ...
end

class SignUp < ActiveType::Record[User]
  ...
end

user = User.find(1)
sign_up = ActiveType.cast(user, SignUp)
sign_up.is_a?(SignUp) # => true
```

This is basically like [`ActiveRecord#becomes`](http://apidock.com/rails/v4.2.1/ActiveRecord/Persistence/becomes), but with less bugs and more consistent behavior.

You can also cast an entire relation (scope) to a relation of an `ActiveType::Record`:

```
adult_users = User.where('age >= 18')
adult_sign_ups = ActiveType.cast(adult_users, SignUp)
sign_up = adult_sign_ups.find(1)
sign_up.is_a?(SignUp) # => true
```


Supported Rails versions
------------------------

ActiveType is tested against ActiveRecord 3.2, 4.0, 4.1 and 4.2.

Later versions might work, earlier will not.

Supported Ruby versions
------------------------

ActiveType is tested against MRI 1.8.7 (for 3.2 only), 1.9.3, 2.0.0, 2.1.2.


Installation
------------

In your `Gemfile` say:

    gem 'active_type'

Now run `bundle install` and restart your server.


Development
-----------

- We run tests against several ActiveRecord versions.
- You can bundle all versions with `rake all:install`.
- You can run specs against all versions with `rake all:spec`.
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


