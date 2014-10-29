defmodule Kalends.AmbiguousDateTime do
  @moduledoc """
  AmbiguousDateTime provides a struct which represents a certain time and date
  in a certain time zone. These structs will be returned from the
  DateTime.from_erl/2 function when the provided time is ambiguous.

  The possible_date_times field contains a list of the two possible DateTime
  structs.
  """
  defstruct [:possible_date_times]
end
