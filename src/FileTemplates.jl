"""
Functionality for handling the defautl conent of the various Genie files (migrations, models, controllers, etc).
"""
module FileTemplates

using Genie.Inflector


"""
    new_task(module_name::String) :: String

Default content for a new Genie task.
"""
function newtask(module_name::String) :: String
  """
  module $module_name

  using Genie, Genie.Toolbox


  \"\"\"
  Description of the task here
  \"\"\"
  function run_task()
    # Build something great
  end

  end
  """
end
const new_task = newtask


"""
    newcontroller(controller_name::String) :: String

Default content for a new Genie controller.
"""
function newcontroller(controller_name::String) :: String
  """
  module $(controller_name)Controller
  # Build something great
  end
  """
end
const new_controller = newcontroller


"""
    newtest(plural_name::String, singular_name::String) :: String

Default content for a new test file.
"""
function newtest(plural_name::String, singular_name::String) :: String
  """
  using Genie, App.$(plural_name)

  ### Your tests here
  @test 1 == 1
  """
end
const new_test = newtest


"""
"""
function appmodule(path::String)
  path = replace(path, "-"=>"_") |> strip
  appname = split(path, "/", keepempty = false)[end] |> String |> Inflector.from_underscores

  content = """
  module $appname

  using Genie, Genie.Router, Genie.Renderer, Genie.AppServer

  function main()
    Base.eval(Main, :(const UserApp = $appname))

    include(joinpath("..", "genie.jl"))

    Base.eval(Main, :(const Genie = $appname.Genie))
    Base.eval(Main, :(using Genie))
  end; main()

  end
  """

  (appname, content)
end

end
