# Changelog

## [0.11.1] - 2015-11-04
### Fixed

- Bug when no translation module was configured.

## [0.11.0] - 2015-11-04
### Changed

- Added a protocol for translations: `Calendar.CalendarTranslations`.
  A module `Calendar.DefaultTranslations` is included and used by default.
  Calendar can be configured to use another module for translations.

- Date.days_after_until/2 is now days_after_until/3 with the 3rd argument
  for an option to include the first argument in the result.

### Added

- DateTime.Parse.httpdate!/1 function to complement httpdate/1
- Date.to_erl and Time.to_erl functions accepts any input that implements
  the correct Contains... protocol

## [0.10.2] - 2015-09-29
### Changed

- Make Strftime functions work better with more kinds of input

### Added

- Make NaiveDateTime.to_erl and .to_micro_erl accept any argument that implements ContainsNaiveDateTime.
- add .iex.exs file alias Calendar.TimeZoneData.

## [0.10.1] - 2015-09-18
### Added

- Add protocol for DateTime
- add .iex.exs file with aliases for DateTime, Date, Time etc.

## [0.10.0] - 2015-08-25

### Changed

- Now supports Tzdata ~> 0.5.1

## [0.9.0] - 2015-08-11
### Added

- Support for Elixir 1.1.0-dev

### Removed

- Range functionality via Range.Iterator has been removed for Date and Time.
  This was done because it is not going to be supported in Elixir 1.1

## [0.8.1] - 2015-08-08
### Changed

- Date.dates_for_week_number/2 now returns a list instead of a Range.
  This was done because custom ranges will probably be deprecated in the future.

### Added

- Time.diff/2 function (Fabian Keunecke)
- Time.to_micro_erl function that returns a four-tuple with usec

## [0.8.0] - 2015-07-14
### Changed

- DateTime.now/1 has been deprecated in favor of DateTime.now!/1
- Deprecate strftime! functions that are not in the Strftime module
  Existing code calling strftime functions should use the same function
  with the Strftime module instead.

### Added

- Strftime module
- function with_offset_to_datetime_utc to NaiveDateTime
- ISO 8601 Basic formatting to DateTime.Format
- Date function for day of week numbers with 0 being Sunday
- Date funciion day_number_in_year
- DateTime.Parse rfc822
- second_in_day and from_second_in_day functions to Time
- Date now has a function for week ranges
- For NaiveDateTime protocol accept micro erl style tuples

## [0.7.0] - 2015-07-07
### Added

- Add protocols for Date, Time, NaiveDateTime for polymorphism
- Range functionality for Date
- Date: `day_of_the_week` function
- Date: boolean functions for weekdays e.g. `monday?`
- Time: functions for 12 hour clock: `pm?`, `am?`, `twelve_hour_time`
- DateTime.Format: format `DateTime`s as RFC 822 & RFC 850
- Add new module NaiveDateTime.Format

## [0.6.9] - 2015-07-05
### Added
- DateTime.Format: rfc2822 function for formatting DateTimes as RFC 2822
- DateTime: Added parsing of RFC 2822 & 1123 datetime strings
- NaiveDateTime.Parse: Added parsing of "C time" strings
- NaiveDateTime functions: advance, advance!, gregorian_seconds

### Changed
- In strftime %z no longer includes a colon

## [0.6.8] - 2015-06-16
### Changed
- DateTime.Parse.rfc3339_utc/1 and rfc3339/2 functions now allow no seperators
  between year, month, date, hour etc. E.g. "19961219T163957-08:00".

### Added
- NaiveDateTime.Parse module added with an iso8601 function to parse ISO 8601
  datetimes. With or without offsets.

## [0.6.7] - 2015-05-23
### Changed

DateTime.Parse.rfc3339_utc/1 and rfc3339/2 functions can now parse timestamps
where there is no colon in the offset. For instance:
rfc3339_utc("1996-12-19T16:39:57-0800")

## [0.6.6] - 2015-05-18
### Changed

The library has been renamed from Kalends to Calendar.
In your code replace Kalends with Calendar and :kalends with :calendar

### Removed!

`stream` functions have been removed!
The functions `days_after` and `days_after_until` replace them.

### Added

Added to Date module:

- `advance` and `advance!` functions
- `days_after`, `days_after_until` functions
- `days_before`, `days_before_until` functions

## [0.6.5] - 2015-05-08
### Added

- `diff` function added to DateTime
- `diff` function added to Date
- `strftime!` function added to Date

## [0.6.4] - 2015-04-23
### Added

- `advance` functions added to DateTime

## [0.6.3] - 2015-04-09
### Added

- DateTime now has proper validation of the time part of datetimes. This
  includes validating leap seconds. Date times with the second being "60"
  will be validated based on whether it is actually a known leap second.

- TimeZoneData has functions for accessing known leap seconds.

- Timezone shifting supports leap seconds.

### Changed

- Use version 0.1.1 of tzdata. This greatly improves performance. Also
  it means that years above 2200 are now supported. Year 0 to 9999 should
  now work.

## [0.6.2] - 2015-04-03
### Changed

Use version 0.1.0 of `tzdata` library that has a slightly different API
than before.

## [0.6.1] - 2015-03-21
### Added

Unix timestamp parsing can parse strings.

### Changed

Updated tzdata dependency to version 0.0.2, which has tz release version
2015b.

## [0.6.0] - 2015-03-18
### Added

Functions DateTime.from_micro_erl_total_off/3 and from_erl_total_off/4
which takes an erlang style datetime (or "micro erlang" style), a time zone,
and a total UTC offset. In case the datetime is ambiguous
the functions try to disambiguise the time based on the total UTC offset.

## [0.5.2] - 2015-03-14
### Added

DateTime.Format.rfc3339/2 function added. Like rfc3339/1, but takes second
parameter to specify number of decimals.

## [0.5.1] - 2015-03-08
### Added

to_micro_erl functions added to DateTime and NaiveDateTime. These functions
return datetime tuples with 4 elements in the time part, the fourth one
being microseconds.

### Changed

DateTime. now_utc function now uses :os.timestamp instead of :erlang.now
internally for more accuracy and less overhead.

## [0.5.0] - 2015-03-05
### Changed

The microseconds part of the DateTime, NaiveTime and Time structs have been
renamed from microsec to usec.

## [0.4.1] - 2015-03-02
### Added

Important addition: tzdata is now in applications in mix.exs

## [0.4.0] - 2015-03-02
### Changed

DateTime.Format.iso8601 function renamed to DateTime.Format.rfc3339.

## [0.3.0] - 2015-02-26
### Changed

Extracted tzdata parsing and moved it to a new library: `tzdata`.
tzdata package added as a dependency in mix.exs.
