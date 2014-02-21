Edge Rider [![Build Status](https://secure.travis-ci.org/makandra/active_type.png?branch=master)](https://travis-ci.org/makandra/active_type)
====================================

Power tools for ActiveRecord relations (scopes)
-------------------------------------------------

In ActiveRecord, relations (or scopes) allow you to construct complex queries piece-by-piece
and then trigger a query or update at a precisely defined moment. If you write any kind
of scalable code with ActiveRecord, you are probably using relations (or scopes) to do it.

Edge Rider was created with two intents:

1. Provides a number of utility methods to facilitate hardcore work with relations.
2. Provide a stable API for working with relations across multiple versions of Rails (since
Rails has a tradition of breaking details of its relation API every other release).

It has been tested with Rails 2.3, 3.0 and 3.2.


Usage
-----

### Traversing a relation along an association

Edge Rider gives your relations a method `#traverse_association` which
returns a new relation by "pivoting" around a named association.

Say we have a `Post` model and each `Post` belongs to an author:

    class Post < ActiveRecord::Base
      belongs_to :author
    end
  
To turn a relation of posts into a relation of its authors:

    posts = Post.where(:archived => false)
    authors = posts.traverse_association(:author)
    
You can traverse multiple associations in a single call.
E.g. to turn a relation of posts into a relation of all posts of their authors:

    posts = Post.where(:archived => false)
    posts_by_same_authors = posts.traverse_association(:author, :posts)

*Implementation note:* The traversal is achieved internally by collecting all foreign keys in the current relation
and return a new relation with an `IN(...)` query (which is very efficient even for many thousand keys).
This means every association that you pivot around will trigger one SQL query.


### Efficiently collect all record IDs in a relation

You often want to retrieve an array of all record IDs in a relation.

You should **not** use `relation.collect(&:id)` for this because a call like that
will instantiate a potentially large number of ActiveRecord objects only to collect
its ID.

Edge Rider has a better way. Your relations gain a method `#collect_ids` that will
fetch all IDs in a single query without instantiating a single ActiveRecord object:

    posts = Post.where(:archived => false)
    post_ids = posts.collect_ids

*Implemenation note:* In Rails 3.2+, `#collect_ids` delegates to [`#pluck`](http://apidock.com/rails/ActiveRecord/Calculations/pluck),
which can be used for the same purpose.


### Collect record IDs from any kind of object

When writing a method that filters by record IDs, you can make it more useful by accepting
any kind of argument that can be turned into a list of IDs:

    Post.by_author(1)
    Post.by_author([1, 2, 3])
    Post.by_author(Author.find(1))
    Post.by_author([Author.find(1), Author.find(2)])
    Post.by_author(Author.active)

For this use case Edge Rider defines `#collect_ids` on many different types:

    Post.where(:id => [1, 2]).collect_ids    # => [1, 2, 3]
    [Post.find(1), Post.find(2)].collect_ids # => [1, 2]
    Post.find(1).collect_ids                 # => [1]
    [1, 2, 3].collect_ids                    # => [1, 2, 3]
    1.collect_ids                            # => [1]

You can now write `Post.by_author` from the example above without a single `if` or `case`:

    class Post < ActiveRecord::Base
    
      belongs_to :author

      def self.for_author(author_or_authors)
        where(:author_id => author_or_authors.collect_ids)
      end

    end
    
    
### Efficiently collect all values in a relation's column

You often want to ask a relation for an array of all values ofin a given column.

You should **not** use `relation.collect(&:column)` for this because a call like that
will instantiate a potentially large number of ActiveRecord objects only to collect
its column value.

Edge Rider has a better way. Your relations gain a method `#collect_column` that will
fetch all column values in a single query without instantiating a single ActiveRecord object:

    posts = Post.where(:archived => false)
    subjects = posts.collect_column(:subject)

*Implementation note:* In Rails 3.2+, `#collect_column` delegates to [`#pluck`](http://apidock.com/rails/ActiveRecord/Calculations/pluck),
which can be used for the same effect.

#### Collect unique values in a relation's column

If you only care about *unique* values, use the `:distinct => true` option:

    posts = Post.where(:archived => false)
    distinct_subjects = posts.collect_column(:subject, :distinct => true)

With this options duplicates are discarded by the database before making their way into Ruby.

*Implementation note:* In Rails 3.2+, the `:distinct` option is implemented with [`#uniq`](http://apidock.com/rails/ActiveRecord/QueryMethods/uniq)
 which can be used for the same effect.


### Retrieve the SQL a relation would produce

Sometimes it is useful to ask a relation which SQL query it would trigger,
if it was evaluated right now. For this, Edge Rider gives your relations a method
`#to_sql`:

    # Rails 2 scope
    Post.scoped(:conditions => { :id => [1, 2] }).to_sql 
    # => SELECT `posts`.* FROM `posts` WHERE `posts.id` IN (1, 2)

    # Rails 3 relation
    Post.where(:id => [1, 2]).to_sql 
    # => SELECT `posts`.* FROM `posts` WHERE `posts.id` IN (1, 2)

*Implementation note*: Rails 3+ implements `#to_sql`. Edge Rider backports this method to Rails 2 so you can use it
regardless of your Rails version.


### Simplify a complex relation for better chainability

In theory you can take any relation and extend it with additional joins or conditions.
We call this *chaining** relations.

In practice chaining becomes problematic as relation chains grow more complex.
In particular having JOINs in your relation will reduce the relations's ability to be chained with additional JOINs
without crashes or side effects. This is because ActiveRecord doesn't really "understand" your relation chain, it only
mashes together strings that mostly happen to look like a MySQL query in the end.

Edge Rider gives your relations a new method `#to_id_query`:

    Site.joins(:user).where(:users => { :name => 'Bruce' }).to_id_query

`#to_id_query` will immediately run an SQL query where it collects all the IDs that match your relation:

    SELECT sites.id FROM sites INNER JOIN users WHERE sites.user_id = sites.id AND users.name = 'Bruce'

It now uses these IDs to return a new relation that has **no joins** and a single condition on the `id` column:

    SELECT * FROM sites WHERE sites.user_id IN (3, 17, 103)


### Preload associations for loaded ActiveRecords

Sometimes you want to fetch associations for records that you already instantiated, e.g. when it has deeply nested associations.

Edge Rider gives your model classes a method `.preload_associations`. The method can be used to preload associations for loaded objects like this:

    @user = User.find(params[:id])
    User.preload_associations [@user], { :threads => { :posts => :author }, :messages => :sender }

*Implementation note*: Rails 2.3 and Rails 3.0 already has a method [`.preload_associations`](http://apidock.com/rails/ActiveRecord/AssociationPreload/ClassMethods/preload_associations)
which Edge Rider merely makes public. Edge Rider ports this method forward to Rails 3.1+.


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


