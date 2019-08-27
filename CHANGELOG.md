# Changelog

## [1.0.0] - 2019-08-27

- No changes since 1.0.0-rc1

## [1.0.0-rc1] - 2019-08-22
## Added

- Added RFC 5455 DateTime formatting and parsing

## [1.0.0-rc0] - 2019-08-20
## Changed

- Removed deprecated Calendar.DateTime.TzPeriod. See version 0.18.0 for alternatives
- Removed deprecated Calendar.TimeZoneData. See version 0.18.0 for alternatives

## [0.18.0] - 2019-08-07
## Changed

- Deprecated the Calendar.TimeZoneData module. The Tzdata library can be used instead.
- Deprecated the Calendar.DateTime.TzPeriod module
- Requires a minimum of Elixir version 1.4 instead of previously 1.3

## Fixed

- No longer has a deprecation warning for `deprecated time unit: :milliseconds` in newer Elixir versions

## [0.17.6] - 2019-04-23
## Added

- tzdata dependency version ~> 1.0 allowed

## [0.17.5] - 2019-03-28
## Fixed

- Fix loss of microsecond resolution when using DateTime.from_naive/2. thanks to jamesotron
- Fix error when using Calendar.DateTime.Parse.rfc3339_utc/1 with missing offset. thanks to erikreedstrom

## [0.17.4] - 2017-08-12
### Changed

- Get rid of warnings in Elixir 1.5.

## [0.17.3] - 2017-07-12
### Changed

- Allow Elixir versions ~1.3 in mix.exs, which means Elixir 1.5+ is allowed.

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



