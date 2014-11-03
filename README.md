Kalends
=======

Kalends is a date and time library for Elixir.

It is a priority to provide timezone information that is as accurate as
possible. The Olson/Eggert "Time Zone Database" is used. Years 1 through 2200
are supported.

[![Build
Status](https://travis-ci.org/lau/kalends.svg?branch=master)](https://travis-ci.org/lau/kalends)

## Usage examples

Get a DateTime struct for the 4th of October 2014 at 23:44:32 in the city of
Montevideo:

    {:ok, mvd} = Kalends.DateTime.from_erl {{2014,10,4},{23,44,32}}, "America/Montevideo"
    {:ok, %Kalends.DateTime{abbr: "UYT", date: 4, hour: 23, min: 44, month: 10,
                            sec: 32, std_off: 0, timezone: "America/Montevideo",
                            utc_off: -10800, year: 2014}}

A DateTime struct is now assigned to the variable `mvd`. Let's get a DateTime
struct for the same time in the London time zone:

    london = mvd |> Kalends.DateTime.shift_zone! "Europe/London"
    %Kalends.DateTime{abbr: "BST", date: 5, hour: 3, min: 44, month: 10,
                      sec: 32, std_off: 3600, timezone: "Europe/London",
                      utc_off: 0, year: 2014}

In UTC:

    london |> Kalends.DateTime.shift_zone! "UTC"
    %Kalends.DateTime{abbr: "UTC", ambiguous: {false, nil}, date: 5, hour: 2,
     min: 44, month: 10, sec: 32, std_off: 0, timezone: "UTC", utc_off: 0,
     year: 2014}

Transforming a DateTime to a string in ISO 8601 / RFC 3339 format:

    mvd |> Kalends.Formatter.iso8601
    "2014-10-04T23:44:32-03:00"

Parsing the same string again back into a DateTime:

    Kalends.Parser.parse_rfc3339 "2014-10-04T23:44:32-03:00", "America/Montevideo"
    {:ok, %Kalends.DateTime{abbr: "UYT", date: 4, hour: 23, min: 44,
            month: 10, sec: 32, std_off: 0, timezone: "America/Montevideo",
            utc_off: -10800, year: 2014}}

Parsing a UTC RFC 3339 timestamp:

    Kalends.Parser.parse_rfc3339 "2014-10-04T23:44:32Z", "UTC"
    {:ok, %Kalends.DateTime{abbr: "UTC", date: 4, hour: 23, min: 44,
            month: 10, sec: 32, std_off: 0, timezone: "UTC",
            utc_off: 0, year: 2014}}

The time right now for a specified time zone:

    cph = Kalends.DateTime.now "Europe/Copenhagen"
    %Kalends.DateTime{abbr: "CEST", date: 5, hour: 21,
     min: 59, month: 10, sec: 24, std_off: 3600, timezone: "Europe/Copenhagen",
     utc_off: 3600, year: 2014}

Transform a DateTime struct to an Erlang style tuple:

    cph |> Kalends.DateTime.to_erl
    {{2014, 10, 5}, {21, 59, 24}}

## Documentation

Documentation can be found at http://hexdocs.pm/kalends/

## Raison d'être

There are many different rules for time zones all over the world and they change
often. In order to correctly find out what time it is around the world, the
"tz database" is invaluable. This is (AFAIK) the first pure Elixir library that
uses the tz database and can easily be updated whenever a new version is
released.

## Time Zone Database updates

The time zone database (tzdata) is regularly updated. When a new tzdata
version is released, developers of Kalends can easily download the new version
simply by running a command. Then when compiling Kalends, the new tzdata will be
used.

## Known bugs

There are no confirmed bugs as this is written. But if you do find a problem,
please create an issue on the GitHub page.

## License

Kalends is released under the MIT license. See the LICENSE file.

The tzdata (found in the tzdata directory) is public domain.
