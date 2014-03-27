ActiveType
==========

Make any Ruby object quack like ActiveRecord
--------------------------------------------

ActiveType is our take on doing "presenter models" (or "form models") in Rails. We want to have controllers (and views) talk to models that either are not backed by a database table, or have additional functionality that should not be shared to the rest of the application.

We do not want to lose ActiveRecord's amenities, like validations and callbacks.

Examples for both use case are a models to support sign in:

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

and model to support sign up:

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

- Test applications for various Rails versions lives in `spec`.
- You need to create a MySQL database and put credentials into `spec/shared/app_root/config/database.yml`.
- You can bundle all test applications by saying `bundle exec rake all:bundle`
- You can run specs from the project root by saying `bundle exec rake all:spec`.

If you would like to contribute:

- Fork the repository.
- Push your changes **with passing specs**.
- Send me a pull request.

I'm very eager to keep this gem leightweight and on topic. If you're unsure whether a change would make it into the gem, [talk to me beforehand](mailto:henning.koch@makandra.de).


Credits
-------

Henning Koch from [makandra](http://makandra.com/)


