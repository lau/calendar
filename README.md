Calendar
=======

Calendar is a datetime library for Elixir.

Providing explicit types for datetimes, dates and times.
Full timezone support via its sister package [tzdata](https://github.com/lau/tzdata).

Safe parsing and formatting of standard formats (ISO, RFC, Unix, JS etc.)
plus strftime formatting. Easy and safe interoperability with erlang style
date, time, datetime tuples. Extendable through protocols.

Related packages are available for [i18n](https://github.com/padde/calendar_translations) interoperability.

[Documentation is available on hexdocs.](http://hexdocs.pm/calendar/)

## Elixir standard library

Since the Calendar library was started, a lot of functionality previously only available in the Calendar library is now also available in the Elixir standard library. With Elixir 1.8 and later you can do time zone conversion in the [DateTime module of the Elixir standard library](https://hexdocs.pm/elixir/DateTime.html) provided you are using the [tzdata library](https://github.com/lau/tzdata#getting-started).

Certain features like more advanced formatting are not yet available in the Elixir standard library. In these case this library is useful.

## Getting started

Add Calendar as a dependency to an Elixir project by adding it to your mix.exs file:

```elixir
defp deps do
  [  {:calendar, "~> 1.0.0"},  ]
end
```

Then run `mix deps.get` which will fetch Calendar via the hex package manager.

## Types

Since Elixir 1.3 the types used are now built into the Elixir standard library.

* `Date` - a simple date without time e.g. `2015-12-24`
* `Time` - a simple time without a date e.g. `14:30:00` or `15:21:12.532985`
* `NaiveDateTime` - datetimes without timezone information e.g. `2015-12-24 14:30:00`
* `DateTime` - datetimes where the proper timezone name is known e.g. `2015-12-24 14:30:00` in `America/New_York` or `2015-12-24 17:30:00` in `Etc/UTC`

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

## Polymorphism and protocols

The functions of each module are appropriate for that type. For instance the `Date` module has a function `next_day!` that returns a `Date` struct for the next day of a provided date. Any Calendar type that contains a date can be used as an argument. So in addition to `Date`, a `DateTime` or `NaiveDateTime` can be used. Also erlang-style tuples with a date or date-time can be used. Example:

```elixir
{2015, 12, 24} |> Calendar.Date.next_day!
~D[2015-12-25]
```

And using a NaiveDateTime containing the date 2015-12-24 would also return a Date struct for 2015-12-25:

```elixir
Calendar.NaiveDateTime.from_erl!({{2015, 12, 24}, {13, 45, 55}}) |> Calendar.Date.next_day!
~D[2015-12-25]
```

In the same fashion other tuples with at least the same amount of information can be used with other modules. E.g.` NaiveDateTime`, `DateTime`, `Time` structs can be used in the `Time` module because they all contain an hour, minute and second. `DateTime` structs and erlang style datetime tuples can be used in the `NaiveDateTime` module because they contain a date and a time.

`File.lstat!/2` is an example of a function that returns datetime tuples.
A datetime tuple can be used in place of a NaiveDateTime, Date or Time.
```elixir
# Returns the mtime of the file mix.exs
> File.lstat!("mix.exs").mtime
{{2015, 12, 31}, {14, 30, 26}}
# Format this datetime using one of the NaiveDateTime fun
File.lstat!("mix.exs").mtime |> Calendar.NaiveDateTime.Format.asctime
"Thu Dec 31 14:30:26 2015"
# Using the tuple with the Date class, the date information is used
> File.lstat!("mix.exs").mtime |> Calendar.Date.day_of_week_name
"Thursday"
# We know from the erlang documentation that lstat! by default returns UTC.
# But the tuple does not contain this information.
# So we can explicitly cast the tuple to be a DateTime in UTC.
# And then pipe that to the DateTime.Format.unix function in order to get a UNIX timestamp
> File.lstat!("mix.exs").mtime |> Calendar.NaiveDateTime.to_date_time_utc |> Calendar.DateTime.Format.unix
1451572226
# String formatting
> File.lstat!("mix.exs").mtime |> Calendar.Strftime.strftime!("%H:%M:%S")
"14:30:26"
```

## Date examples

The Date module is used for handling dates.

```elixir
# You can create a new date with the from_erl! function:
> jan_first = {2015, 1, 1} |> Calendar.Date.from_erl!
~D[2015-01-01]
# Get a date that is 10000 days ahead of that one
> ten_k_days_later = jan_first |> Calendar.Date.add!(10000)
~D[2042-05-19]
# Is it friday?
> jan_first |> Calendar.Date.friday?
false
# What day of the week is it?
> jan_first |> Calendar.Date.day_of_week_name
"Thursday"

# Compare dates
> jan_first |> Calendar.Date.before?({2015, 12, 24})
true
# Get the difference in days between two dates. Using the Elixir 1.3 Date sigil.
> jan_first |> Calendar.Date.diff(~D[2015-12-24])
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
[~D[2016-06-13], ~D[2016-06-14], ~D[2016-06-15], ~D[2016-06-16],
 ~D[2016-06-17], ~D[2016-06-18], ~D[2016-06-19]]
```

## NaiveDateTime

Use NaiveDateTime modules when you have a date-time, but do not know the
timezone.

```elixir
# An erlang style datetime tuple advanced 10 seconds
{{1999, 12, 31}, {23, 59, 59}} |> Calendar.NaiveDateTime.add!(10)
~N[2000-01-01 00:00:09]
# Parse a "C Time" string.
> {:ok, ndt} = "Wed Apr  9 07:53:03 2003" |> Calendar.NaiveDateTime.Parse.asctime
{:ok, ~N[2003-04-09 07:53:03]}
# Calendar.NaiveDateTime.Format.asctime can take a naive datetime and format it
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
> ndt |> Calendar.NaiveDateTime.after?(~N[2003-04-08 10:00:00])
true
```

## DateTime usage examples

The time right now for a specified time zone:

```elixir
cph = Calendar.DateTime.now! "Europe/Copenhagen"
%DateTime{calendar: Calendar.ISO, day: 14, hour: 5, microsecond: {496149, 6}, minute: 27, month: 6, second: 14, std_offset: 3600,
 time_zone: "Europe/Copenhagen", utc_offset: 3600, year: 2016, zone_abbr: "CEST"}
```

Get a DateTime struct for the 4th of October 2014 at 23:44:32 in the city of
Montevideo:

```elixir
{:ok, mvd} = Calendar.DateTime.from_erl {{2014,10,4},{23,44,32}}, "America/Montevideo"
{:ok,
 %DateTime{calendar: Calendar.ISO, day: 4, hour: 23, microsecond: {0, 0}, minute: 44, month: 10, second: 32, std_offset: 0,
  time_zone: "America/Montevideo", utc_offset: -10800, year: 2014, zone_abbr: "-03"}}
```

A DateTime struct is now assigned to the variable `mvd`. Let's get a DateTime
struct for the same time in the London time zone:

```elixir
london = mvd |> Calendar.DateTime.shift_zone!("Europe/London")
%DateTime{calendar: Calendar.ISO, day: 5, hour: 3, microsecond: {0, 0}, minute: 44, month: 10, second: 32, std_offset: 3600,
 time_zone: "Europe/London", utc_offset: 0, year: 2014, zone_abbr: "BST"}
```

...and then in UTC:

```elixir
london |> Calendar.DateTime.shift_zone!("Etc/UTC")
%DateTime{calendar: Calendar.ISO, day: 5, hour: 2, microsecond: {0, 0}, minute: 44, month: 10, second: 32, std_offset: 0, time_zone: "Etc/UTC",
 utc_offset: 0, year: 2014, zone_abbr: "UTC"}
```

Transforming a DateTime to a string in ISO 8601 / RFC 3339 format:

```elixir
> mvd |> Calendar.DateTime.Format.rfc3339
"2014-10-04T23:44:32-03:00"
# or ISO 8601 basic
> mvd |> Calendar.DateTime.Format.iso8601_basic
"20141004T234432-0300"
```

Format as a unix timestamp:

```elixir
mvd |> Calendar.DateTime.Format.unix
1412477072
```

Format as milliseconds that can be used by JavaScript:

```elixir
mvd |> Calendar.DateTime.Format.js_ms
1412477072000
# Can be used like this in Javascript: new Date(1412477072000)
```

Parsing an RFC 3339 timestamp as UTC:

```elixir
{:ok, parsed} = Calendar.DateTime.Parse.rfc3339_utc "2014-10-04T23:44:32.4999Z"
{:ok,
 %DateTime{calendar: Calendar.ISO, day: 4, hour: 23, microsecond: {499900, 4}, minute: 44, month: 10, second: 32, std_offset: 0, time_zone: "Etc/UTC",
  utc_offset: 0, year: 2014, zone_abbr: "UTC"}}
# Format the parsed DateTime as ISO 8601 Basic
parsed |> Calendar.DateTime.Format.iso8601_basic
"20141004T234432Z"
```

Transform a DateTime struct to an Erlang style tuple:

```elixir
cph |> Calendar.DateTime.to_erl
{{2016, 6, 14}, {5, 27, 14}}
```

Make a new `%DateTime{}` struct in the future from a tuple by adding 1800 seconds.

```elixir
Calendar.DateTime.from_erl!({{2014,10,4},{23,44,32}}, "Europe/Oslo") |> Calendar.DateTime.add(1800)
{:ok,
 %DateTime{calendar: Calendar.ISO, day: 5, hour: 0, microsecond: {0, 0}, minute: 14, month: 10, second: 32, std_offset: 3600,
  time_zone: "Europe/Oslo", utc_offset: 3600, year: 2014, zone_abbr: "CEST"}}
```

Create DateTime struct from :os.timestamp / erlang "now" format:

```
> {1457, 641101, 48030} |> Calendar.DateTime.from_erlang_timestamp
%DateTime{calendar: Calendar.ISO, day: 10, hour: 20, microsecond: {48030, 6}, minute: 18, month: 3, second: 21, std_offset: 0, time_zone: "Etc/UTC",
 utc_offset: 0, year: 2016, zone_abbr: "UTC"}
```

## Documentation

Documentation can be found at http://hexdocs.pm/calendar/


## Elixir versions earlier than 1.3

If you are using an Elixir version earlier than 1.3, use Calendar version `~> 0.14.2`
This version accepts the Calendar structs from earlier versions (e.g. `%Calendar.DateTime`)
And additionally when running on Elixir 1.3 or higher, it accepts the built in calendar
types present in Elixir 1.3 (e.g. `%DateTime`). But Calendar structs are always returned.

## Raison d'être

The purpose of Calendar is to have an easy to use library for handling
dates, time and datetimes that gives correct results.

Instead of treating everything as a datetime, the different
types (Date, Time, NaiveDateTime, DateTime) provide clarity and safety
from certain bugs.

Before Calendar, there was no Elixir library with
correct time zone support. The timezone information was later
extracted from Calendar into the Tzdata library.

## Video presentation with some Calendar examples

In [a talk from ElixirConf 2015](http://img.youtube.com/vi/keUbVvMJeKY/0.jpg) Calendar is featured. Specifically from around 27:07 into the video there are some
Calendar examples.

[![Talk from ElixirConf 2015](http://img.youtube.com/vi/keUbVvMJeKY/0.jpg)](http://www.youtube.com/watch?v=keUbVvMJeKY)

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
project.

## License

Calendar is released under the MIT license. See the LICENSE file.
