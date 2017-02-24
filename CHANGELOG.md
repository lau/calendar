# Changelog

## [0.17.2] - 2017-02-23
### Changed

- NaiveDateTime and DateTime parsing of RFC3339 and ISO 8601 allows commas as the sign
  for fractional seconds.

## [0.17.1] - 2017-01-15

### Fixed

- Get rid of last warning in Elixir 1.4

## [0.17.0] - 2017-01-08

### Fixed

- Get rid of warnings in Elixir 1.4 (Lasse Ebert)

### Changed

- The function Calendar.DateTime.now/1 was previously deprecated. It has been changed
  to returns the same as Calendar.DateTime.now!/1 but as a tuple tagged with :ok. Note that
  this is a breaking change for those using the deprecated version in 0.16.1.
  If you were using now/1 with earlier versions of Calendar, you could use now!/1 instead.

## [0.16.1] - 2016-08-25

### Added

- Calendar.DateTime.Parse.unix! function can handle microseconds when provided with a string.
  E.g. Calendar.DateTime.Parse.unix!("1000000000.01")

### Fixed

- Deprecated iso_8601_basic format function was broken.

## [0.16.0] - 2016-06-13

This version only works on Elixir 1.3.0 and newer.
Use ~> 0.14.2 for Elixir 1.2 or earlier.

### Changes



