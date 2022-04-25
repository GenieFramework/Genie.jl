"""
Functionality for handling the defautl conent of the various Genie files (migrations, models, controllers, etc).
"""
module FileTemplates

import Inflector


"""
    newtask(module_name::String) :: String

Default content for a new Genie Toolbox task.
"""
function newtask(module_name::String) :: String
  """
  module $module_name

  \"\"\"
  Description of the task here
  \"\"\"
  function runtask()
    # Build something great
  end

  end
  """
end


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


"""
    appmodule(path::String)

Generates a custom app module when a new app is bootstrapped.
"""
function appmodule(path::String)
  path = replace(path, '-'=>'_') |> strip
  appname = split(path, '/', keepempty = false)[end] |> String |> Inflector.from_underscores

  content = """
  module $appname

  using Genie

  const up = Genie.up
  export up

  function main()
    Genie.genie(; context = @__MODULE__)
  end

  end
  """

  (appname, content)
end

end
