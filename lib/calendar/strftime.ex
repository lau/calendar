defmodule Calendar.Strftime do
  @moduledoc """
  Format different types of time representations as strings.
  """

  # documentation for this is in Calendar.Formatter
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
  defp string_for_conv_spec(dt, :f, _) do micro_seconds(dt) end
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
  defp string_for_conv_spec(dt, :c, _) do strftime! dt, "%a %b %e %T %Y" end
  defp string_for_conv_spec(dt, :m, _) do "#{dt.month}"|>pad end
  defp string_for_conv_spec(dt, :e, _) do "#{dt.day}"|>pad(2, hd ' ') end
  defp string_for_conv_spec(dt, :d, _) do "#{dt.day}"|>pad end
  defp string_for_conv_spec(dt, :H, _) do "#{dt.hour}"|>pad end
  defp string_for_conv_spec(dt, :k, _) do "#{dt.hour}"|>pad(2, hd ' ') end
  defp string_for_conv_spec(dt, :M, _) do "#{dt.min}"|>pad end
  defp string_for_conv_spec(dt, :S, _) do "#{dt.sec}"|>pad end
  defp string_for_conv_spec(dt, :z, _) do z_offset_part(dt) end
  defp string_for_conv_spec(dt, :Z, _) do "#{dt.abbr}" end

  defp micro_seconds(dt) do
    "#{dt.usec}"
  end

  defp pad(subject, len\\2, char\\?0) do
    String.rjust("#{subject}", len, char)
  end

  defp z_offset_part(dt) do
    total_off = dt.utc_off + dt.std_off
    sign = sign_for_offset(total_off)
    offset_amount_string = total_off |> secs_to_hours_mins_string
    sign<>offset_amount_string
  end
  defp sign_for_offset(offset) when offset < 0, do: "-"
  defp sign_for_offset(_), do: "+"
  defp secs_to_hours_mins_string(secs) do
    secs = abs(secs)
    hours = secs/3600.0 |> Float.floor |> trunc
    mins = rem(secs, 3600)/60.0 |> Float.floor |> trunc
    "#{hours|>pad(2)}#{mins|>pad(2)}"
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

  defp iso_week_number(dt) do
    dt |> Calendar.Date.week_number
  end

  defp day_number_in_year(dt) do
    dt |> Calendar.Date.day_number_in_year
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
    dt |> Calendar.Date.day_of_week
  end
  defp names_for_language(:en) do
    %{weekdays: ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"],
      weekdays_abbr: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
      months: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"],
      months_abbr: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"],
    }
  end
  defp names_for_language(:da) do
    %{weekdays: ["mandag", "tirsdag", "onsdag", "torsdag", "fredag", "lørdag", "søndag"],
      weekdays_abbr: ["man", "tir", "ons", "tor", "fre", "lør", "søn"],
      months: ["Januar", "Februar", "Marts", "April", "Maj", "Juni", "Juli", "August", "September", "Oktober", "November", "December"],
      months_abbr: ["jan", "feb", "mar", "apr", "maj", "jun", "jul", "aug", "sep", "okt", "nov", "dec"],
    }
  end
  defp names_for_language(:es) do
    %{weekdays: ["lunes", "martes", "miércoles", "jueves", "viernes", "sábado", "domingo"],
      weekdays_abbr: ["lun", "mar", "mié", "jue", "vie", "sáb", "dom"],
      months: ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre" ],
      months_abbr: ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"],
    }
  end
  defp names_for_language(_) do
    raise "unknown language code"
  end
end
