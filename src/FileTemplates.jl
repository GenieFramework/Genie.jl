"""
Functionality for handling the defautl conent of the various Genie files (migrations, models, controllers, etc).
"""
module FileTemplates

using Genie.Inflector


"""
    new_task(module_name::String) :: String

Default content for a new Genie task.
"""
function new_task(module_name::String) :: String
  """
  module $module_name

  using Genie, Genie.Toolbox


  \"\"\"
  Description of the task here
  \"\"\"
  function run_task!()
    # Build something great
  end

  end
  """
end


"""
    new_controller(controller_name::String) :: String

Default content for a new Genie controller.
"""
function new_controller(controller_name::String) :: String
  """
  module $(controller_name)Controller
  # Build something great
  end
  """
end


"""
    new_channel(channel_name::String) :: String

Default content for a new Genie channel.
"""
function new_channel(channel_name::String) :: String
  """
  module $(channel_name)Channel

  using Genie.Channels


  function subscribe()
    Channels.subscribe(wsclient(@params), :$(lowercase(channel_name)))
    "OK"
  end

  end
  """
end


"""
    new_authorizer() :: String

Default content for a new Genie ACL YAML file.
"""
function new_authorizer() :: String
  """
  admin:
    create: all
    edit: all
    delete: all
    list: all
  editor:
    edit: all
    list: all
  writer:
    create: all
    edit: own
    delete: own
    list: own
  """
end


"""
    new_test(plural_name::String, singular_name::String) :: String

Default content for a new test file.
"""
function new_test(plural_name::String, singular_name::String) :: String
  """
  using Genie, App.$(plural_name)

  ### Your tests here
  @test 1 == 1
  """
end

end
