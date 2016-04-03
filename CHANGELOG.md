# Changelog

## [0.14.0] - 2016-04-03

This is a "transition" release that will work with both the upcoming
Elixir 1.3 and earlier versions of Elixir.

Elixir 1.3 includes structs that map to the existing structs in Calendar.
E.g. instead of %Calendar.Date there is just %Date.

%Calendar.Date          -> %Date
%Calendar.DateTime      -> %DateTime
%Calendar.NaiveDateTime -> %NaiveDateTime
%Calendar.Time          -> %Time

This version will accept these new types but will return
%Calendar. types. E.g. it will accept a %Date struct but
return a %Calendar.Date struct.

It is adviced to no longer alias the Calendar modules.

In future versions that will only run on Elixir 1.3+, the built in structs
will be replace the ones prepended with %Calendar.

## Deprecated

- The `use Calendar` macro has been deprecated.

## Removed

- .iex.exs file with aliases for DateTime, Date, Time etc.

## [0.13.2] - 2016-03-09
### Added

- DateTime.add and subtract functions added. These will eventually
  replace the deprecated `advance` functions like in other modules (e.g. Date, NaiveDateTime).

## [0.13.1] - 2016-03-01
### Changed

- Fix Elixir 1.1 incompatability.

## [0.13.0] - 2016-03-01
### Changed

- Change `advance` functions to `add`/`subtract`. advance functions are soft-deprecated
- Change DateTime.Format function name from iso_8601_basic to iso8601_basic
  for consistency with the rest of the library. The old name is currently
  soft-deprecated.
- `DateTime.Format.iso_8601_basic/1` renamed to `DateTime.Format.iso8601_basic/1`
  for consistency with similar functions. The old function name is deprecated.

### Added

- `DateTime.Interval`
- `NaiveDateTime.Interval`
- Function `Date.from_ordinal`
- `DateTime.from_erlang_timestamp`
- `DateTime.Format/iso_8601/1` as alias for `rf3339/1`
- Functions to Date: `today_utc/0` and `today!/1`

## [0.12.4] - 2016-01-26
### Improved

- Performance improvements for various formatting functions

The changelog has been truncated. See earlier versions for more changelog.
