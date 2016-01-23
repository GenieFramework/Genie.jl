type Welcome_Controller <: Jinnie_Controller
end

function index(_::Welcome_Controller, req)
  render(req, data=Dict("user_name" => "Adrian!!!"))
end