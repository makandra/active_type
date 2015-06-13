# ActiveType Change Log

All notable changes to this project will be documented in this file.

ActiveType is in a pre-1.0 state. This means that its APIs and behavior are subject to breaking changes without deprecation notices. Until 1.0, version numbers will follow a [Semver][]-ish `0.y.z` format, where `y` is incremented when new features or breaking changes are introduced, and `z` is incremented for lesser changes or bug fixes.

## [Unreleased]

* Your contribution here!

## [0.4.0][] (2015-06-12)

* Add ActiveType.cast to cast ActiveRecord instances and relations to extended models

## [0.3.5][] (2015-06-11)

* Make gem crash during loading with ActiveRecord 4.2.0 because [#31](https://github.com/makandra/active_type/issues/31)

## [0.3.4][] (2015-03-14)

* Support belongs_to associations for ActiveRecord 4.2.1
* Ensure that ActiveType::Object correctly validates boolean attributes (issue [#34](https://github.com/makandra/active_type/issues/34))

## [0.3.3][] (2015-01-23)

* Don't crash for database types without casting rules (fixes [#25](https://github.com/makandra/active_type/issues/25))

## [0.3.2][] (2015-01-22)

* Making the gem to work with Rails version 4.0.0
* Use native database type for type casting in pg

## [0.3.1][] (2014-11-19)

* Support nested attributes in extended records (fixes [#17](https://github.com/makandra/active_type/issues/17))

## [0.3.0][] (2014-09-23)

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
