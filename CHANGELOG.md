# ActiveType Change Log

All notable changes to this project will be documented in this file.

## Unreleased changes

## 1.5.0 (2020-11-06)

* Added: When serializing/deserializing `ActiveType::Record` or `ActiveType::Object` with YAML, virtual attributes are restored.
  Credits to @chriscz.

## 1.4.2 (2020-09-17)

* Fixed: Assigning values to virtual attributes through internal setter methods (e.g. `_write_attribute`) no longer results in "can't write unknown attribute" errors.

## 1.4.1 (2020-08-05)

* Fixed: Avoid `Module#parents` deprecation warning on Rails 6. Thanks to @cilim.

## 1.4.0 (2020-07-27)

* Extended records now use their own I18n namespace when looking up translations for models or attributes.
  If the extended record's namespace does not contain a translation, the lookup will fall back to the
  base record's namespace.

  For instance, given the following class hierarchy:

  ```
  class User < ActiveRecord::Base
  end

  class User::Form < ActiveType::Record[User]
  end
  ```

  The call `ExtendedParent.human_attribute_name(:foo)` would first look up the key in
  `activerecord.attributes.user/form` first, then falls back to `activerecord.attributes.user`.

  Thank you @fsateler!


## 1.3.2 (2020-06-16)

* Fixed: `nests_one` association record building used empty hash instead of passed in attributes. Credit to @chriscz.


## 1.3.1 (2020-03-31)

* Fixed: Avoid #change_association breaking for polymorphic associations. Thanks to @lucthev.


## 1.3.0 (2019-09-26)

* Fixed: Do not override Rails internal methods when definining an attribute called `:attribute`.
* Fixed: Fix .find for extended records, when a record had a `#type` column that was not used for
  single table inheritance. Thanks to @fsateler.
* Changed: When extending a single table inheritance base class, `.find` no longer crashes, but
  returns records derived from the extended class.

  This means, that given the following class hierarchy:

  ```ruby
  class Parent < ActiveRecord::Base
  end

  class ExtendedParent < ActiveType::Record[Parent]
  end

  class Child < Parent
  end
  ```

  querying

  ```
  ExtendedParent.all
  ```

  will no longer crash, but always return records of type `ExtendedParent` (*even if they
  would normally of type `Child`*). You should probably avoid this weird situation and not
  extend STI Parent classes.

  Thanks to @fsateler.


## 1.2.1 (2019-07-03)
* Fixed: Eager loading in Rails 6 no longer crashes trying to load `ActiveType::Object`s.
  Thanks to @teamhqapp for the fix.


## 1.2.0 (2019-06-18)

* Fixed: Using `has_many` et al in an extended record ignored given scopes.
* Added: `change_association` on ActiveType::Record to change assocation options.


## 1.1.1 (2019-05-07)

* Improved dirty tracking (`#changes?` etc) for virtual attributes to bring it more in line with
  the behaviour of non-virtual attributes. Behaviour with ActiveRecord < 4 remains unchanged.
  Thanks to @lowski.

## 1.1.0 (2019-03-04)

* For some use cases, users need to access ActiveRecord's original `.attribute` method, which ActiveType overrides. We now alias `.attribute` as `.ar_attribute`.
* In a `ActiveRecord::Record[MyRecord]`, `.has_many` now guesses `"my_record_id"` as the foreign key. Same for `.has_one`.

## 1.0.0 (2019-02-15)

* No code changes.
* Modernize list of supported Rails versions and Rubies.


## 0.7.5 (2017-12-04)

* Fixed an `chird record did not match id` exception introduced in the 0.7.3 update when using `nests_one`. Credit to @cerdiogenes.


## 0.7.4 (2017-09-01)

* Bugfix: ActiveType.cast sets #type correctly when casting to an STI class

## 0.7.3 (2017-08-16)

* `nests_many` / `nests_one` will now work for nested records with non-integer primary keys.


## 0.7.2 (2017-07-31)

* Fixed a bug when converting datetimes from certain strings. This occured if the string included an explicit time zone (i.e. `record.date_time = '2017-07-31 12:30+03:00'`), which was not the local time.

## 0.7.1 (2017-06-19)

* ActiveType::Object no longer requires a database connection on Rails 5+ (it never did on Rails 3 or 4).

## 0.7.0 (2017-04-21)

* Support `index_errors: true` for `nest_many`.

## 0.6.4 (2017-02-27)

* Fix an issue when using `ActiveType.cast` "too early".

## 0.6.3 (2017-01-30)

* Fix a load error when using `ActiveType::Object` before using `ActiveRecord::Base` within a Rails app.

## 0.6.2 (2017-01-30)

* When used with Rails, defer loading to not interfere with `ActiveRecord` configuration in initializers.

## 0.6.1 (2016-12-05)

* Remove spec folder from packaged gem.

## 0.6.0 (2016-07-05)

* Drop support for 1.8.7.
* Rails 5 compatibility.

## 0.5.1 (2016-05-09)

* Fix an issue with incorrectly copied errors on Util.cast.

## 0.5.0 (2016-04-08)

* Nicer `#inspect` method.

## 0.4.5 (2016-02-01)

* Fixed issue `#dup`ing `ActiveType::Object`

## 0.4.4 (2016-01-18)

* Call `#after_commit` for `ActiveType::Object`

## 0.4.3 (2015-11-11)

* Fix issue with Booleans on mysql.

## 0.4.2 (2015-09-24)

* Add `attribute_will_change!` for virtual attributes.

## 0.4.1 (2015-09-24)

* Add `attribute_was` for virtual attributes.

## 0.4.0 (2015-06-12)

* Add ActiveType.cast to cast ActiveRecord instances and relations to extended models

## 0.3.5 (2015-06-11)

* Make gem crash during loading with ActiveRecord 4.2.0 because [#31](https://github.com/makandra/active_type/issues/31)

## 0.3.4 (2015-03-14)

* Support belongs_to associations for ActiveRecord 4.2.1
* Ensure that ActiveType::Object correctly validates boolean attributes (issue [#34](https://github.com/makandra/active_type/issues/34))

## 0.3.3 (2015-01-23)

* Don't crash for database types without casting rules (fixes [#25](https://github.com/makandra/active_type/issues/25))

## 0.3.2 (2015-01-22)

* Making the gem to work with Rails version 4.0.0
* Use native database type for type casting in pg

## 0.3.1 (2014-11-19)

* Support nested attributes in extended records (fixes [#17](https://github.com/makandra/active_type/issues/17))

## 0.3.0 (2014-09-23)

* Add support for Rails 4.2beta

[Semver]: http://semver.org
[Unreleased]: https://github.com/makandra/active_type/compare/v0.4.0...HEAD
[0.4.0]: https://github.com/makandra/active_type/compare/v0.3.5...v0.4.0
[0.3.5]: https://github.com/makandra/active_type/compare/v0.3.4...v0.3.5
[0.3.4]: https://github.com/makandra/active_type/compare/v0.3.3...v0.3.4
[0.3.3]: https://github.com/makandra/active_type/compare/v0.3.2...v0.3.3
[0.3.2]: https://github.com/makandra/active_type/compare/v0.3.1...v0.3.2
[0.3.1]: https://github.com/makandra/active_type/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/makandra/active_type/compare/v0.2.1...v0.3.0
