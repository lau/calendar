# Changelog

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
