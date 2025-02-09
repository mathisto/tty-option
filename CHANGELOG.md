# Change log

## [v0.2.1] - unreleased

### Fixed
* Fix argument check against permitted values to allow nil value when optional

## [v0.2.0] - 2021-08-04

### Added
* Add predicate methods for checking if a given parameter is supported

### Changed
* Change Conversions to stop raising error and return Undefined value instead
* Change to skip conversion of parameters with nil value

### Fixed
* Fix conversion of nil into array or hash to stop raising an error
* Fix #no_command to correctly mark command as not present
* Fix warnings about shadowing local variables

## [v0.1.0] - 2020-05-18

* Initial implementation and release

[v0.2.1]: https://github.com/piotrmurach/tty-option/compare/v0.2.0...v0.2.1
[v0.2.0]: https://github.com/piotrmurach/tty-option/compare/v0.1.0...v0.2.0
[v0.1.0]: https://github.com/piotrmurach/tty-option/compare/95179f0...v0.1.0
