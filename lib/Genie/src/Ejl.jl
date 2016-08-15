module Ejl
using SHA
using Genie

export @ejl_str, push_template_line!

const THROW_EXCEPTIONS = true
const CACHE_PATH = joinpath(Genie.APP_PATH, "cache", "ejl")
const WITH_CACHE = Genie.RENDER_EJL_WITH_CACHE

macro ejl_str(p)
  parse_tpl(p)
end

function cache!(status::Bool)
  WITH_CACHE = status
end

function clear_cache()
  for cache_file in readdir(CACHE_PATH)
    rm(joinpath(CACHE_PATH, cache_file))
  end
end

function cache_path(s::AbstractString)
  cache_name = bytes2hex(sha1(s))
  joinpath(CACHE_PATH, cache_name)
end

function check_cache(s::AbstractString)
  isfile(cache_path(s))
end

function tpl_from_cache(s::AbstractString)
  cache = open(cache_path(s), "r") do (io)
    deserialize(io)
  end
end

function tpl_to_cache(s::AbstractString)
  open(cache_path(s), "w") do (io)
    serialize(io, s)
  end
end

function template_from_file(file_path::AbstractString)
  open(file_path) do f
    parse_tpl(readall(f))
  end
end

function parse_tpl(s::AbstractString)
  WITH_CACHE && check_cache(s) && return tpl_from_cache(s)

  s = """$s"""
  const code = Array{AbstractString,1}()
  push!(code, "____output = Vector{AbstractString}()")

  const current_line::Int = 0
  const lines_of_template::Vector{AbstractString} = split(s, "\n")

  const in_block                = false
  const end_block               = false
  const block_content           = Vector{AbstractString}()
  const block_suspended         = false
  const suspend_block           = false
  const cmd::AbstractString     = ""

  function include_partial(tpl_line::AbstractString)
    open(joinpath(Genie.APP_PATH, strip(strip_start_markup(tpl_line)))) do f
      readall(f) |> Ejl.parse_tpl |> Ejl.render_tpl
    end
  end

  function debug_line(tpl_line::AbstractString)
    debug_tpl(tpl_line)
    "%= " * strip_start_markup(tpl_line)
  end

  function start_block!()
    in_block = true
    block_content = Vector{AbstractString}()
    true
  end

  function end_block!()
    end_block = true
    true
  end

  function enter_block!()
    block_suspended = false
    suspend_block = false
    true
  end

  function exit_block!()
    suspend_block = true
    true
  end

  function push_to_output!(expr::AbstractString)
    push!(code, expr)
    true
  end

  function push_to_block!(s::AbstractString)
    push!(block_content, s)
    true
  end

  function reset_block!()
    block_content = Vector{AbstractString}()
    in_block = false
    end_block = false
    block_suspended = false
    true
  end

  function whitespaces!(s::AbstractString)
    line_has_no_nl(s) ? s = strip_end_markup(s) : s *= ""
    s = replace(s, "%%", " ")
    s
  end

  function push_template_line!(s::AbstractString)
    cmd = "push!(____output, \"$(escape_string(whitespaces!(s)))\")"
    in_block && push_to_block!(cmd) && return true
    push_to_output!(cmd) && return true
  end

  function debug_tpl(tpl_line::AbstractString)
    @show current_line
    @show tpl_line
    @show block_content
    @show in_block
    @show end_block
    @show block_suspended
    @show suspend_block
    @show code

    true
  end

  for tpl_line in lines_of_template
    current_line += 1

    try
      line_is_comment(tpl_line) && continue

      line_is_debug(tpl_line) && (tpl_line = debug_line(tpl_line))

      line_is_include(tpl_line) && (tpl_line = include_partial(tpl_line))

      if ( line_is_block_start(tpl_line) && start_block!() ) ||
         ( line_is_block_enter(tpl_line) && enter_block!() )
        tpl_line = strip_start_markup(tpl_line)
        isempty(tpl_line) && continue
      end

      if ( line_is_block_end(tpl_line) && end_block!() ) ||
         ( line_is_block_exit(tpl_line) && exit_block!() )
        tpl_line = strip_end_markup(tpl_line)
      end

      line_is_code_exec(tpl_line) && strip_start_markup(tpl_line) |> push_to_output! && continue

      if line_is_code_exec_output(tpl_line)
        output_identifier = "____" * randstring(24)
        "$output_identifier = $((strip_start_markup(whitespaces!(tpl_line))))" |> push_to_output!
        "push!(____output, \"\$($output_identifier)\")" |> push_to_output!

        continue
      end

      if in_block && ! block_suspended
        push_to_block!(tpl_line)
        suspend_block && (block_suspended = true)
        end_block && join(block_content, "\n") |> push_to_output! && reset_block!()

        continue
      end

      push_template_line!(tpl_line)

    catch parse_exception
      println("EjlParseException in template at line $current_line: $(lines_of_template[current_line])")
      @show(parse_exception)

      println()
      println("Debug data:")
      debug_tpl(tpl_line)
      println()

      THROW_EXCEPTIONS && rethrow(parse_exception)
    end
  end

  WITH_CACHE && tpl_to_cache(join(code, "\n"))

  code
end

function is_valid_markup(s::AbstractString)
  ! isempty(strip(s)) && length(strip(s)) >= 2
end

function line_is_comment(s::AbstractString)
  is_valid_markup(s) && (lstrip(s)[1:2] == "#%" || lstrip(s)[1:2] == "#<" || lstrip(s)[1:2] == "# ")
end

function line_is_include(s::AbstractString)
  is_valid_markup(s) && lstrip(s)[1:2] == "%+"
end

function line_is_debug(s::AbstractString)
  is_valid_markup(s) && lstrip(s)[1:2] == "%_"
end

function line_is_block_start(s::AbstractString)
  is_valid_markup(s) && lstrip(s)[1:2] == "<%"
end

function line_is_block_end(s::AbstractString)
  is_valid_markup(s) && end_markup(s) == "%>"
end

function line_is_block_enter(s::AbstractString)
  is_valid_markup(s) && lstrip(s)[1:2] == "<:"
end

function line_is_block_exit(s::AbstractString)
  is_valid_markup(s) && end_markup(s) == ":>"
end

function line_is_code_exec(s::AbstractString)
  is_valid_markup(s) && lstrip(s)[1:2] == "%-"
end

function line_is_code_exec_output(s::AbstractString)
  is_valid_markup(s) && lstrip(s)[1:2] == "%="
end

function line_has_no_nl(s::AbstractString)
  is_valid_markup(s) && end_markup(s) == "%&"
end

function line_has_space_guard(s::AbstractString)
  is_valid_markup(s) && end_markup(s) == "%%"
end

function strip_start_markup(s::AbstractString)
  s = lstrip(s)
  if length(s) > 2
    lstrip(s[3:end])
  else
    ""
  end
end

function strip_end_markup(s::AbstractString)
  rstrip(s)[1:prevind(s, length(s)-1)] |> rstrip
end

function end_markup(s::AbstractString)
  s[prevind(s, length(s)):end]
end

function render_tpl(exs::Vector{AbstractString})
  __helper = """
  ____output = Vector{AbstractString}()

  function _push_out!_(s::AbstractString)
    push!(____output, escape_string(s))
  end
  """

  exs = __helper * join(exs, "\n")
  join(include_string(exs), "\n")
end

end