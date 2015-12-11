Calendar
=======
### (formerly known as Kalends)

[![Build
Status](https://travis-ci.org/lau/calendar.svg?branch=master)](https://travis-ci.org/lau/calendar)
[![Inline docs](http://inch-ci.org/github/lau/calendar.svg)](http://hexdocs.pm/calendar/)
[![Hex Version](http://img.shields.io/hexpm/v/calendar.svg?style=flat)](https://hex.pm/packages/calendar)

Calendar is a date and time library for Elixir.

The Olson/Eggert "Time Zone Database" is used. Years 1 through 9999
are supported.

## Getting started

Add Calendar as a dependency to an Elixir project by adding it to your mix.exs file:

```elixir
defp deps do
  [  {:calendar, "~> 0.12.0"},  ]
end
```

Also add `calendar` to the list of applications in the mix.exs file:

```elixir
  def application do
    [applications: [:logger, :calendar]]
  end
```

Then run `mix deps.get` which will fetch Calendar via the hex package manager.

## Upgrading from versions earlier than 0.10.0

Calendar 0.10.0 supports Tzdata ~> 0.5.1 as well as ~> 0.1.7

With Tzdata 0.5.1 it is now necessary to have calendar in the application list
as described above in the "Getting started" secion.

## Types

Calendar has 4 basic types of structs:

* `Date` - a simple date without time e.g. `2015-12-24`
* `Time` - a simple time without a date e.g. `14:30:00` or `15:21:12.532985`
* `NaiveDateTime` - datetimes without timezone information e.g. `2015-12-24 14:30:00`
* `DateTime` - datetimes where the proper timezone name is known e.g. `2015-12-24 14:30:00` in `America/New_York` or `2015-12-24 17:30:00` in `Etc/UTC`

## Polymorphism and protocols

The functions of each module are appropriate for that type. For instance the `Date` module has a function `next_day!` that returns a `Date` struct for the next day of a provided date. Any Calendar type that contains a date can be used as an argument. So in addition to `Date`, a `DateTime` or `NaiveDateTime` can be used. Also erlang-style tuples with a date or date-time can be used. Example:

```elixir
{2015, 12, 24} |> Calendar.Date.next_day!
%Calendar.Date{day: 25, month: 12, year: 2015}
```

And using a NaiveDateTime containing the date 2015-12-24 would also return a Date struct for 2015-12-25:

```elixir
Calendar.NaiveDateTime.from_erl!({{2015, 12, 24}, {13, 45, 55}}) |> Calendar.Date.next_day!
%Calendar.Date{day: 25, month: 12, year: 2015}
```

In the same fashion other tuples with at least the same amount of information can be used with other modules. E.g.` NaiveDateTime`, `DateTime`, `Time` structs can be used in the `Time` module because they all contain an hour, minute and second. `DateTime` structs and erlang style datetime tuples can be used in the `NaiveDateTime` module because they contain a date and a time.

## Date examples

The Date module is used for handling dates.

```elixir
# You can create a new date with the from_erl! function:
> jan_first = {2015, 1, 1} |> Calendar.Date.from_erl!
%Calendar.Date{day: 1, month: 1, year: 2015}
# Get a date that is 10000 days ahead of that one
> ten_k_days_later = jan_first |> Calendar.Date.advance!(10000)
%Calendar.Date{day: 19, month: 5, year: 2042}
# Is it friday?
> jan_first |> Calendar.Date.friday?
false
# What day of the week is it?
> jan_first |> Calendar.Date.day_of_week_name
"Thursday"
# In Spanish by passing :es as language code
jan_first |> Calendar.Date.day_of_week_name :es
"jueves"

# Compare dates
> jan_first |> Calendar.Date.before?({2015, 12, 24})
true
> jan_first |> Calendar.Date.diff({2015, 12, 24})
-357
# Because of protocols, datetimes can also be provided as arguments,
# but only the date will be used
> jan_first |> Calendar.Date.diff({{2015, 12, 24}, {9, 10, 10}})
-357

# Use the DateTime module to get the time right now and
# pipe it to the Date module to get the week number
> Calendar.DateTime.now_utc |> Calendar.Date.week_number
{2015, 28}
# Pipe the week number tuple into another function to get a list
# of the dates for that week
> Calendar.DateTime.now_utc |> Calendar.Date.week_number |> Calendar.Date.dates_for_week_number
[%Calendar.Date{day: 6, month: 7, year: 2015},
 %Calendar.Date{day: 7, month: 7, year: 2015},
 %Calendar.Date{day: 8, month: 7, year: 2015},
 %Calendar.Date{day: 9, month: 7, year: 2015},
 %Calendar.Date{day: 10, month: 7, year: 2015},
 %Calendar.Date{day: 11, month: 7, year: 2015},
 %Calendar.Date{day: 12, month: 7, year: 2015}]

```

## NaiveDateTime

Use NaiveDateTime modules when you have a date-time, but do not know the
timezone.

```elixir
# An erlang style datetime tuple advanced 10 seconds
{{1999, 12, 31}, {23, 59, 59}} |> Calendar.NaiveDateTime.advance!(10)
%Calendar.NaiveDateTime{day: 1, hour: 0, min: 0, month: 1, sec: 9, usec: nil,
 year: 2000}
# Parse a "C Time" string.
> {:ok, ndt} = "Wed Apr  9 07:53:03 2003" |> Calendar.NaiveDateTime.Parse.asctime
{:ok,
 %Calendar.NaiveDateTime{day: 9, hour: 7, min: 53, month: 4, sec: 3, usec: nil,
  year: 2003}}
# NaiveDateTime.Format.asctime can take a naive datetime and format it
# as a as a C time string. We format the NaiveDateTime struct we just got from
# parsing and get the same result as the original input:
> ndt |> Calendar.NaiveDateTime.Format.asctime
"Wed Apr  9 07:53:03 2003"
# Compare with another naive datetime in the form of an erlang style datetime tuple
# Returns the difference in seconds, microseconds and if it is before after or at the
# same time
> ndt |> Calendar.NaiveDateTime.diff({{2003, 4, 8}, {10, 0, 0}})
{:ok, 78783, 0, :after}
# There are also boolean functions to just find out if a naive datetime is before or
# after another one
> ndt |> Calendar.NaiveDateTime.after? {{2003, 4, 8}, {10, 0, 0}}
true
```

## DateTime usage examples

For these example first either alias DateTime with this command: `alias Calendar.DateTime` or for use within a module add `use Calendar` to the module.

The time right now for a specified time zone:

```elixir
cph = DateTime.now! "Europe/Copenhagen"
%Calendar.DateTime{abbr: "CEST", day: 5, hour: 21,
 min: 59, month: 10, sec: 24, std_off: 3600, timezone: "Europe/Copenhagen",
 usec: 678805, utc_off: 3600, year: 2014}
```

Get a DateTime struct for the 4th of October 2014 at 23:44:32 in the city of
Montevideo:

```elixir
{:ok, mvd} = DateTime.from_erl {{2014,10,4},{23,44,32}}, "America/Montevideo"
{:ok,
 %Calendar.DateTime{abbr: "UYT", day: 4, hour: 23, min: 44, month: 10, sec: 32,
  std_off: 0, timezone: "America/Montevideo", usec: nil, utc_off: -10800,
  year: 2014}}
```

A DateTime struct is now assigned to the variable `mvd`. Let's get a DateTime
struct for the same time in the London time zone:

```elixir
london = mvd |> DateTime.shift_zone! "Europe/London"
%Calendar.DateTime{abbr: "BST", day: 5, hour: 3, min: 44, month: 10, sec: 32,
 std_off: 3600, timezone: "Europe/London", usec: nil, utc_off: 0, year: 2014}
```

...and then in UTC:

```elixir
london |> DateTime.shift_zone! "Etc/UTC"
%Calendar.DateTime{abbr: "UTC", day: 5, hour: 2, min: 44, month: 10, sec: 32,
 std_off: 0, timezone: "Etc/UTC", usec: nil, utc_off: 0, year: 2014}
```

Transforming a DateTime to a string in ISO 8601 / RFC 3339 format:

```elixir
> mvd |> DateTime.Format.rfc3339
"2014-10-04T23:44:32-03:00"
# or ISO 8601 basic
> mvd |> DateTime.Format.iso_8601_basic
"20141004T234432-0300"
```

Format as a unix timestamp:

```elixir
mvd |> DateTime.Format.unix
1412477072
```

Parsing an RFC 3339 timestamp as UTC:

```elixir
{:ok, parsed} = DateTime.Parse.rfc3339_utc "2014-10-04T23:44:32.4999Z"
{:ok, %Calendar.DateTime{abbr: "UTC", day: 4, usec: 499900, hour: 23,
        min: 44, month: 10, sec: 32, std_off: 0, timezone: "Etc/UTC",
        utc_off: 0, year: 2014}}
# Format the parsed DateTime as ISO 8601 Basic
parsed |> DateTime.Format.iso_8601_basic
"20141004T234432Z"
```

Transform a DateTime struct to an Erlang style tuple:

```elixir
cph |> DateTime.to_erl
{{2014, 10, 5}, {21, 59, 24}}
```

Make a new DateTime from a tuple and advance it 1800 seconds.

```elixir
DateTime.from_erl!({{2014,10,4},{23,44,32}}, "Europe/Oslo") |> DateTime.advance(1800)
{:ok,
 %Calendar.DateTime{abbr: "CEST", day: 5, hour: 0, min: 14, month: 10, sec: 32,
  std_off: 3600, timezone: "Europe/Oslo", usec: nil, utc_off: 3600, year: 2014}}
```

## String formatting

Calendar has polymorphic string formatting that does not get you into
trouble by silently using fake data.

If you need a well known format, such as RFC 3339 the `DateTime.Format` and
`NaiveDateTime.Format` modules have functions for a lot of those. In case you
want to do something custom or want to format simple `Date`s or `Time`s, you
can use the `Strftime` module. It uses formatting strings already known from
the strftime "standard".

The strftime function takes all the struct types: Date, Time, DateTime,
NaiveDateTime and datetime tuples. You just have to make sure that the
conversion specs (the codes with the %-signs) are appropriate for whatever is
input.

```elixir
# a Date struct works fine with these conversion specs (%a, %d, %m, %y)
# because they just require a date
Calendar.Date.from_erl!({2014,9,6}) |> Calendar.Strftime.strftime "%a %d.%m.%y"
{:ok, "Sat 06.09.14"}
# A tuple like this is treated as a NaiveDateTime and also works because
# it contains a date.
{{2014,9,6}, {12, 13, 34}} |> Calendar.Strftime.strftime "%a %d.%m.%y"
{:ok, "Sat 06.09.14"}
# Trying to use date conversion specs and passing a Time struct results in an
# error because a Time struct does not have the year or any other of the
# data necessary for the string "%a %d.%m.%y"
Calendar.Time.from_erl!({12, 30, 59}) |> Calendar.Strftime.strftime "%a %d.%m.%y"
{:error, :missing_data_for_conversion_spec}
```

## Documentation

Documentation can be found at http://hexdocs.pm/calendar/

## Ecto

If you want to use Calendar with Ecto, there is a library for that:
Calecto https://github.com/lau/calecto

This makes it easy to save the different types of time and date
representations to a database. And later work with them in an easy and
safe manner.

## Phoenix

If you want to use Calendar with Phoenix, there is a library that
takes care of that: https://github.com/lau/phoenix_calendar

## Raison d'être

The purpose of Calendar is to have an easy to use library for handling
dates, time and datetimes that gives correct results.

Instead of treating everything as a datetime, the different
types (Date, Time, NaiveDateTime, DateTime) provide clarity and safety
from certain bugs.

Before Calendar, there was no Elixir library with
correct time zone support. The timezone information was later
extracted from Calendar into the Tzdata library.

## "use" macro

You can then call Calendar functions like this: `Calendar.DateTime.now_utc`. But in order to avoid typing Calendar all the time you can add `use Calendar` to your modules. This aliases Calendar modules such as `DateTime`, `Time`, `Date` and `NaiveDateTime`. Which means that you can call for instance `DateTime.now_utc` without writing `Calendar.` Example:

```elixir
defmodule NewYearsHttpLib do
  use Calendar

  def httpdate_new_years(year) do
    {:ok, dt} = DateTime.from_erl({{year,1,1},{0,0,0}}, "Etc/UTC")
    DateTime.Format.httpdate(dt)
  end

  # Calling httpdate_new_years(2015) will return
  # "Thu, 01 Jan 2015 00:00:00 GMT"
end
```

## Name change from Kalends, upgrade instructions.

For existing users of Kalends: Kalends has changed its name to Calendar. To upgrade:
- In your code replace all instances of `Kalends` with `Calendar`
- In your code replace all instances of `:kalends` with `:calendar`
- In case you are also using Kalecto, it has changed its name to
  [Calecto](https://github.com/lau/calecto). In a similair
  fashion replace `Kalecto` with `Calecto` and `:kalecto` with `:calecto`
- In your `mix.exs` file make sure you are specifying a valid version of :calendar

## Known bugs

There are no confirmed bugs as this is written. But if you do find a problem,
please create an issue on the GitHub page: https://github.com/lau/calendar

## Trouble shooting

Problem: an error like this occours:

```
** (exit) an exception was raised:
    ** (ArgumentError) argument error
        (stdlib) :ets.lookup(:tzdata_current_release, :release_version)
        lib/tzdata/release_reader.ex:41: Tzdata.ReleaseReader.current_release_from_table/0
        lib/tzdata/release_reader.ex:13: Tzdata.ReleaseReader.simple_lookup/1
```

Solution: add :calendar to the application list in the mix.exs file of your
project. Refer to the "Getting started" section of this readme.

## License

Calendar is released under the MIT license. See the LICENSE file.
