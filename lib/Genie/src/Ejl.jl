module Ejl
using Genie, Configuration, SHA, Cache

export @ejl_str, push_template_line!, @ejl

const THROW_EXCEPTIONS = true

macro ejl_str(p)
  parse_tpl(p)
end

function template_from_file(file_path::AbstractString)
  open(file_path) do f
    parse_tpl(readall(f), Genie.cache_enabled())
  end
end

function parse_tpl(s::AbstractString, cache_enabled::Bool)
  ! cache_enabled && return parse_tpl(s)

  with_cache(cache_key(s)) do
    parse_tpl(s)
  end
end

function parse_tpl(s::AbstractString)
  s = """$s"""
  const code = AbstractString[]

  const current_line::Int = 0
  const lines_of_template::Vector{AbstractString} = split(s, "\n")

  block_depth                   = 0
  const in_block                = Dict{Int,Bool}(0 => false)
  const end_block               = Dict{Int,Bool}(0 => false)
  const block_content           = Dict{Int,Vector{AbstractString}}()
  const block_suspended         = Dict{Int,Bool}(0 => false)
  const suspend_block           = Dict{Int,Bool}(0 => false)
  const cmd::AbstractString     = ""

  function include_partial(tpl_line::AbstractString)
    file_name = strip(strip_start_markup(tpl_line))
    file_name = endswith(file_name, "." * RENDER_EJL_EXT) ? file_name : file_name * "." * RENDER_EJL_EXT
    open(joinpath(Genie.APP_PATH, file_name)) do f
      readall(f) |> Ejl.parse_tpl |> Ejl.render_tpl
    end
  end

  function debug_line(tpl_line::AbstractString)
    debug_tpl(tpl_line)
    "%= " * strip_start_markup(tpl_line)
  end

  function start_block!()
    block_depth += 1
    in_block[block_depth] = true
    end_block[block_depth] = false
    block_content[block_depth] = Vector{AbstractString}()
    block_suspended[block_depth] = false
    suspend_block[block_depth] = false

    true
  end

  function end_block!()
    end_block[block_depth] = true
    true
  end

  function enter_block!()
    block_suspended[block_depth] = false
    suspend_block[block_depth] = false

    true
  end

  function exit_block!()
    suspend_block[block_depth] = true
    true
  end

  function push_to_output!(expr::AbstractString)
    push!(code, expr)
    true
  end

  function push_to_block!(s::AbstractString, depth::Int = 0)
    push!(block_content[depth > 0 ? depth : block_depth], s)
    true
  end

  function reset_block!()
    block_content[block_depth] = Vector{AbstractString}()
    in_block[block_depth] = false
    end_block[block_depth] = false
    block_suspended[block_depth] = false
    block_depth -= 1

    true
  end

  function whitespaces!(s::AbstractString)
    line_has_no_nl(s) ? s = strip_end_markup(s) : s *= ""
    s = replace(s, "%%", " ")
    s
  end

  function escape_julia(s::AbstractString)
    s = replace(s, "\\\$", "&dollar;")

    s
  end

  function unescape_embeded_julia(s::AbstractString)
    ! contains(s, "\$(") && ! contains(s, "<\$") && return s

    matches = matchall(r"\$\(.*?\)|<\$.*?\$>", s)
    for m in matches
      s = replace(s, m, unescape_string(m))
      s = replace(s, "<\$", "\$(")
      s = replace(s, "\$>", ")")
    end

    s
  end

  function push_template_line!(s::AbstractString, escape::Bool = false)
    s = whitespaces!(s)
    if escape
      s = escape_string(s)
      s = unescape_embeded_julia(s)
    end
    cmd = """push!(____output, \"$( s )\")"""
    in_block[block_depth] && push_to_block!(cmd) && return true
    push_to_output!(cmd) && return true
  end

  function debug_tpl(tpl_line::AbstractString)
    @show current_line
    @show tpl_line
    @show block_depth
    @show block_content
    @show in_block
    @show end_block
    @show block_suspended
    @show suspend_block
    @show code
    @show current_module()

    true
  end

  for tpl_line in lines_of_template
    current_line += 1
    # @bp

    try
      tpl_line = escape_julia(tpl_line)

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

      if in_block[block_depth] && ! block_suspended[block_depth]
        push_to_block!(tpl_line)
        suspend_block[block_depth] && (block_suspended[block_depth] = true)
        if end_block[block_depth]
          blk_cnt = join(block_content[block_depth], "\n")
          if block_depth == 1
            blk_cnt |> push_to_output!
          else
            push_to_block!(blk_cnt, block_depth - 1)
          end

          reset_block!()
        end

        continue
      end

      push_template_line!(tpl_line, true)

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
  join(include_string(_render_tpl(exs)), "\n")
end

function _render_tpl(exs::Vector{AbstractString})
  """
  const ____output = AbstractString[]

  function _push_out!_(s::AbstractString)
    push!(____output, escape_string(s))
  end

  using ViewHelper, Util, Model

  function __tpl_render__()
    $(join(exs, "\n"))
    return ____output
  end

  __tpl_render__()
  """
end

macro template_from_file(file_path::Expr)
  quote
    @parse_tpl open($file_path) do f
      readall(f)
    end
  end
end

macro parse_tpl(s::Expr)
  :(parse_tpl($s, $(Genie.cache_enabled())))
end

macro render_tpl(exs::Expr)
  :(join(include_string(_render_tpl($exs)), "\n"))
end

macro ejl(path::Expr)
  :( @render_tpl(@template_from_file($path)) )
end

end