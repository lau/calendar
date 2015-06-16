Calendar
=======
### (formerly known as Kalends)

[![Build
Status](https://travis-ci.org/lau/calendar.svg?branch=master)](https://travis-ci.org/lau/calendar)
[![Inline docs](http://inch-ci.org/github/lau/calendar.svg)](http://hexdocs.pm/calendar/)
[![Hex Version](http://img.shields.io/hexpm/v/calendar.svg?style=flat)](https://hex.pm/packages/calendar)

Calendar is a date and time library for Elixir. The only Elixir library with with accurate, up-to-date time zone information.

The Olson/Eggert "Time Zone Database" is used. Years 1 through 9999
are supported.

## Name change from Kalends, upgrade instructions.

For existing users of Kalends: Kalends has changed its name to Calendar. To upgrade:
- In your code replace all instances of `Kalends` with `Calendar`
- In your code replace all instances of `:kalends` with `:calendar`
- In case you are also using Kalecto, it has changed its name to
  [Calecto](https://github.com/lau/calecto). In a similair
  fashion replace `Kalecto` with `Calecto` and `:kalecto` with `:calecto`
- In your `mix.exs` file make sure you are specifying a valid version of :calendar
  (At least version 0.6.6. See the newest version below.)

## Getting started

Add Calendar as a dependency to an Elixir project by adding it to your mix.exs file:

```elixir
defp deps do
  [  {:calendar, "~> 0.6.8"},  ]
end
```

Then run `mix deps.get` which will fetch Calendar via the hex package manager.

You can then call Calendar functions like this: `Calendar.DateTime.now_utc`. But in order to avoid typing Calendar all the time you can add `use Calendar` to your modules. This aliases Calendar modules such as DateTime and Date. Which means that you can call for instance `DateTime.now_utc` without writing `Calendar.` Example:

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

## Usage examples

For these example first either alias DateTime with this command: `alias Calendar.DateTime` or for use within a module add `use Calendar` to the module.

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

Formatting a DateTime using "strftime":

```elixir
mvd |> DateTime.Format.strftime! "The day is %A. The time in 12 hour notation is %I:%M:%S %p"
"The day is Saturday. The time in 12 hour notation is 11:44:32 PM"
```

Transforming a DateTime to a string in ISO 8601 / RFC 3339 format:

```elixir
mvd |> DateTime.Format.rfc3339
"2014-10-04T23:44:32-03:00"
```

Parsing the same string again back into a DateTime:

```elixir
DateTime.Parse.rfc3339 "2014-10-04T23:44:32-03:00", "America/Montevideo"
{:ok, %Calendar.DateTime{abbr: "UYT", day: 4, hour: 23, min: 44, month: 10,
        sec: 32, std_off: 0, timezone: "America/Montevideo", usec: nil,
        utc_off: -10800, year: 2014}}
```

Format as a unix timestamp:

```elixir
mvd |> DateTime.Format.unix
1412477072
```

Parsing an RFC 3339 timestamp as UTC:

```elixir
DateTime.Parse.rfc3339_utc "2014-10-04T23:44:32.4999Z"
{:ok, %Calendar.DateTime{abbr: "UTC", day: 4, usec: 499900, hour: 23,
        min: 44, month: 10, sec: 32, std_off: 0, timezone: "Etc/UTC",
        utc_off: 0, year: 2014}}
```

The time right now for a specified time zone:

```elixir
cph = DateTime.now "Europe/Copenhagen"
%Calendar.DateTime{abbr: "CEST", day: 5, hour: 21,
 min: 59, month: 10, sec: 24, std_off: 3600, timezone: "Europe/Copenhagen",
 usec: 678805, utc_off: 3600, year: 2014}
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

## Documentation

Documentation can be found at http://hexdocs.pm/calendar/

## Ecto

If you want to use Calendar with Ecto, there is a library for that:
Calecto https://github.com/lau/calecto

## Raison d'être

There are many different rules for time zones all over the world and they change
often. In order to correctly find out what time it is around the world, the
"tz database" is invaluable. This is (AFAIK) the first pure Elixir library that
uses the tz database correctly and can easily be updated whenever a new version
is released.

## Known bugs

There are no confirmed bugs as this is written. But if you do find a problem,
please create an issue on the GitHub page: https://github.com/lau/calendar

## License

Calendar is released under the MIT license. See the LICENSE file.
