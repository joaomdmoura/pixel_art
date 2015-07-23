defmodule Phoenix.HTML do
  @moduledoc """
  Helpers for working with HTML strings and templates.

  When used, it imports the given modules:

    * `Phoenix.HTML`- functions to handle HTML safety;

    * `Phoenix.HTML.Tag` - functions for generating HTML tags;

    * `Phoenix.HTML.Form` - functions for working with forms;

    * `Phoenix.HTML.Link` - functions for generating links and urls;

  ## HTML Safe

  One of the main responsibilities of this module is to
  provide convenience functions for escaping and marking
  HTML code as safe.

  By default, data output in templates is not considered
  safe:

      <%= "<hello>" %>

  will be shown as:

      &lt;hello&gt;

  User data or data coming from the database is almost never
  considered safe. However, in some cases, you may want to tag
  it as safe and show its "raw" contents:

      <%= raw "<hello>" %>

  Keep in mind most helpers will automatically escape your data
  and return safe content:

      <%= tag :p, "<hello>" %>

  will properly output:

      <p>&lt;hello&gt;</p>

  """

  @doc false
  defmacro __using__(_) do
    quote do
      import Phoenix.HTML
      import Phoenix.HTML.Form
      import Phoenix.HTML.Link
      import Phoenix.HTML.Tag
    end
  end

  @typedoc "Guaranteed to be safe"
  @type safe    :: {:safe, iodata}

  @typedoc "May be safe or unsafe (i.e. it needs to be converted)"
  @type unsafe  :: Phoenix.HTML.Safe.t

  @doc """
  Provides `~e` sigil with HTML safe EEx syntax inside source files.

      iex> ~e"\""
      ...> Hello <%= "world" %>
      ...> "\""
      {:safe, [[["" | "Hello "] | "world"] | "\\n"]}

  """
  defmacro sigil_e(expr, opts) do
    handle_sigil(expr, opts, __CALLER__.line)
  end

  @doc """
  Provides `~E` sigil with HTML safe EEx syntax inside source files.

  This sigil does not support interpolation and is should be prefered
  rather than `~e`.

      iex> ~E"\""
      ...> Hello <%= "world" %>
      ...> "\""
      {:safe, [[["" | "Hello "] | "world"] | "\\n"]}

  """
  defmacro sigil_E(expr, opts) do
    handle_sigil(expr, opts, __CALLER__.line)
  end

  defp handle_sigil({:<<>>, _, [expr]}, [], line) do
    EEx.compile_string(expr, engine: Phoenix.HTML.Engine, line: line + 1)
  end

  defp handle_sigil(_, _, _) do
    raise ArgumentError, "interpolation not allowed in ~e sigil. " <>
                         "Remove the interpolation or use ~E instead"
  end

  ## Deprecated

  @doc false
  @spec safe(iodata | safe) :: safe
  def safe({:safe, value}) do
    IO.write :stderr, "Phoenix.HTML.safe/1 is deprecated, please use raw/1 instead\n" <>
                      Exception.format_stacktrace()
    {:safe, value}
  end

  def safe(value) when is_binary(value) or is_list(value) do
    IO.write :stderr, "Phoenix.HTML.safe/1 is deprecated, please use raw/1 instead\n" <>
                      Exception.format_stacktrace()
    {:safe, value}
  end

  @doc false
  @spec safe_concat([iodata | safe]) :: safe
  def safe_concat(list) when is_list(list) do
    Enum.reduce(list, {:safe, ""}, &safe_concat(&2, &1))
  end

  @doc false
  @spec safe_concat(iodata | safe, iodata | safe) :: safe
  def safe_concat({:safe, data1}, {:safe, data2}), do: {:safe, io_concat(data1, data2)}
  def safe_concat({:safe, data1}, data2), do: {:safe, io_concat(data1, io_escape(data2))}
  def safe_concat(data1, {:safe, data2}), do: {:safe, io_concat(io_escape(data1), data2)}
  def safe_concat(data1, data2), do: {:safe, io_concat(io_escape(data1), io_escape(data2))}

  defp io_escape(data) when is_binary(data),
    do: Plug.HTML.html_escape(data)
  defp io_escape(data) when is_list(data),
    do: Phoenix.HTML.Safe.List.to_iodata(data)

  defp io_concat(d1, d2) when is_binary(d1) and is_binary(d2) do
    IO.write :stderr, "Phoenix.HTML.safe_concat/2 is deprecated, please use html_escape/1 instead\n" <>
                      Exception.format_stacktrace()
    d1 <> d2
  end

  defp io_concat(d1, d2) do
    IO.write :stderr, "Phoenix.HTML.safe_concat/2 is deprecated, please use html_escape/1 instead\n" <>
                      Exception.format_stacktrace()
    [d1|d2]
  end

  ## Deprecated

  @doc """
  Marks the given content as raw.

  This means any HTML code inside the given
  string won't be escaped.

      iex> raw("<hello>")
      {:safe, "<hello>"}
      iex> raw({:safe, "<hello>"})
      {:safe, "<hello>"}

  """
  @spec raw(iodata | safe) :: safe
  def raw({:safe, value}), do: {:safe, value}
  def raw(value) when is_binary(value) or is_list(value), do: {:safe, value}

  @doc """
  Escapes the HTML entities in the given term, returning iodata.

      iex> html_escape("<hello>")
      {:safe, "&lt;hello&gt;"}

      iex> html_escape('<hello>')
      {:safe, ["&lt;", 104, 101, 108, 108, 111, "&gt;"]}

      iex> html_escape(1)
      {:safe, "1"}

      iex> html_escape({:safe, "<hello>"})
      {:safe, "<hello>"}
  """
  @spec html_escape(unsafe) :: safe
  def html_escape({:safe, _} = safe),
    do: safe
  def html_escape(nil),
    do: {:safe, ""}
  def html_escape(bin) when is_binary(bin),
    do: {:safe, Plug.HTML.html_escape(bin)}
  def html_escape(list) when is_list(list),
    do: {:safe, Phoenix.HTML.Safe.List.to_iodata(list)}
  def html_escape(other),
    do: {:safe, Phoenix.HTML.Safe.to_iodata(other)}

  @doc """
  Converts a safe result into a string.

  Fails if the result is not safe. In such cases, you can
  invoke `html_escape/1` or `raw/1` accordingly before.
  """
  @spec safe_to_string(safe) :: String.t
  def safe_to_string({:safe, iodata}) do
    IO.iodata_to_binary(iodata)
  end
end
