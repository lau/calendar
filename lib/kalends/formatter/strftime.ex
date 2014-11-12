defmodule Kalends.Formatter.Strftime do
  @moduledoc false
  alias Kalends.DateTime, as: DateTime

  # documentation for this is in Kalends.Formatter
  def strftime!(dt, string, lang\\:en) do
    parse_for_con_specs(string)
    |> Enum.reduce(string, fn(conv_spec, new_string) -> String.replace(new_string, "%#{conv_spec}", string_for_conv_spec(dt, conv_spec, lang)) end)
  end

  defp parse_for_con_specs(string) do
    Regex.scan(~r/\%[a-zA-Z]/, string)
    |> Enum.map fn(x) -> hd(x)|>String.replace("%","")|>String.to_atom end
  end

  # Takes for instance a DateTime for 2014-9-6 17:10:20 and :Y and returns "2014"
  defp string_for_conv_spec(dt, :a, lang) do weekday_abbr(dt, lang) end
  defp string_for_conv_spec(dt, :A, lang) do weekday(dt, lang) end
  defp string_for_conv_spec(dt, :b, lang) do month_abbr(dt, lang) end
  defp string_for_conv_spec(dt, :h, lang) do string_for_conv_spec(dt, :b, lang) end
  defp string_for_conv_spec(dt, :B, lang) do month(dt, lang) end
  defp string_for_conv_spec(dt, :j, _) do "#{day_number_in_year(dt)}"|>pad(3) end
  defp string_for_conv_spec(dt, :u, _) do "#{day_of_the_week(dt)}" end
  defp string_for_conv_spec(dt, :w, _) do "#{day_of_the_week_zero_sunday(dt)}" end
  defp string_for_conv_spec(dt, :V, _) do "#{elem(iso_week_number(dt),1)}"|>pad end
  defp string_for_conv_spec(dt, :G, _) do "#{elem(iso_week_number(dt),0)}"|>pad(4) end
  defp string_for_conv_spec(dt, :g, _) do string_for_conv_spec(dt, :G, nil)|>String.slice(-2..-1) end
  defp string_for_conv_spec(dt, :y, _) do "#{dt.year}" |> String.slice(-2..-1) end
  defp string_for_conv_spec(dt, :Y, _) do "#{dt.year}"|>pad(4) end
  defp string_for_conv_spec(dt, :C, _) do "#{(dt.year/100.0)|>trunc}" end
  defp string_for_conv_spec(dt, :I, _) do "#{dt.hour|>x24h_to_12_h|>elem(0)}"|>pad end
  defp string_for_conv_spec(dt, :l, _) do "#{dt.hour|>x24h_to_12_h|>elem(0)}"|>pad(2, hd ' ') end
  defp string_for_conv_spec(dt, :P, _) do "#{dt.hour|>x24h_to_12_h|>elem(1)}" end
  defp string_for_conv_spec(dt, :p, _) do "#{dt.hour|>x24h_to_12_h|>elem(1)}"|>String.upcase end
  defp string_for_conv_spec(dt, :r, _) do strftime! dt, "%I:%M:%S %p" end
  defp string_for_conv_spec(dt, :R, _) do strftime! dt, "%H:%M" end
  defp string_for_conv_spec(dt, :T, _) do strftime! dt, "%H:%M:%S" end
  defp string_for_conv_spec(dt, :F, _) do strftime! dt, "%Y-%m-%d" end
  defp string_for_conv_spec(dt, :m, _) do "#{dt.month}"|>pad end
  defp string_for_conv_spec(dt, :e, _) do "#{dt.date}"|>pad(2, hd ' ') end
  defp string_for_conv_spec(dt, :d, _) do "#{dt.date}"|>pad end
  defp string_for_conv_spec(dt, :H, _) do "#{dt.hour}"|>pad end
  defp string_for_conv_spec(dt, :k, _) do "#{dt.hour}"|>pad(2, hd ' ') end
  defp string_for_conv_spec(dt, :M, _) do "#{dt.min}"|>pad end
  defp string_for_conv_spec(dt, :S, _) do "#{dt.sec}"|>pad end
  defp string_for_conv_spec(dt, :z, _) do iso8601_offset_part(dt) end
  defp string_for_conv_spec(dt, :Z, _) do "#{dt.abbr}" end

  defp pad(subject, len\\2, char\\?0) do
    String.rjust("#{subject}", len, char)
  end

  defp iso8601_offset_part(dt) do
    total_off = dt.utc_off + dt.std_off
    sign = sign_for_offset8601(total_off)
    offset_amount_string = total_off |> secs_to_hours_mins_string
    sign<>offset_amount_string
  end
  defp sign_for_offset8601(offset) when offset < 0, do: "-"
  defp sign_for_offset8601(_), do: "+"
  defp secs_to_hours_mins_string(secs) do
    secs = abs(secs)
    hours = secs/3600.0 |> Float.floor |> trunc
    mins = rem(secs, 3600)/60.0 |> Float.floor |> trunc
    "#{hours|>pad(2)}:#{mins|>pad(2)}"
  end

  defp weekday_abbr(dt, lang) do
    Enum.fetch!(names_for_language(lang)[:weekdays_abbr], day_of_the_week_zero_based(dt))
  end
  defp weekday(dt, lang) do
    Enum.fetch!(names_for_language(lang)[:weekdays], day_of_the_week_zero_based(dt))
  end

  defp month_abbr(dt, lang) do
    Enum.fetch!(names_for_language(lang)[:months_abbr], dt.month-1)
  end
  defp month(dt, lang) do
    Enum.fetch!(names_for_language(lang)[:months], dt.month-1)
  end

  def iso_week_number(dt) do
    {date, _} = DateTime.to_erl(dt)
    :calendar.iso_week_number(date)
  end

  defp day_number_in_year(dt) do
    day_count_previous_months = Enum.map(previous_months_for_month(dt.month),
      fn month ->
        :calendar.last_day_of_the_month(dt.year, month)
      end)
    |> Enum.reduce(0, fn(day_count, acc) -> day_count + acc end)
    day_count_previous_months+dt.date
  end
  # a list or range of previous month names
  defp previous_months_for_month(1), do: []
  defp previous_months_for_month(month) do
    1..(month-1)
  end

  defp day_of_the_week_zero_sunday(dt) do # sunday is 0
    day = day_of_the_week(dt)
    if day == 7 do
      day = 0
    end
    day
  end

  defp x24h_to_12_h(0) do {12, :am} end
  defp x24h_to_12_h(12) do {12, :pm} end
  defp x24h_to_12_h(hour) when hour >= 1 and hour < 12 do {hour, :am} end
  defp x24h_to_12_h(hour) when hour > 12 do {hour - 12, :pm} end

  defp day_of_the_week_zero_based(dt), do: day_of_the_week(dt)-1 # monday is 0
  defp day_of_the_week(dt) do
    {date, _} = DateTime.to_erl(dt)
    :calendar.day_of_the_week(date)
  end
  defp names_for_language(:en) do
    %{
      weekdays: ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"],
      weekdays_abbr: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
      months: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"],
      months_abbr: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"],
    }
  end
end
