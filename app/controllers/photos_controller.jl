type Photos_Controller <: Jinnie_Controller
end

function index(_::Photos_Controller, req)
  tpl = "<h1>Check out my fresh photos at {{:date}}!</h1>"
  render(tpl, data = Dict(:date => Dates.now()))
end

function show(_::Photos_Controller, req)
  println("Photos_Controller::show for GET")
  "Showing photo $(req[:params][:id])"
end

function edit(_::Photos_Controller, req)
  println("Photos_Controller::edit for GET")
  "Showing edit photo form for photo $(req[:params][:id])"
end

function create(_::Photos_Controller, req)
  println("Photos_Controller::create for POST")
  "Creating photos"
end

function update(_::Photos_Controller, req)
  println("Photos_Controller::update for PUT")
  "Updating photos"
end

function destroy(_::Photos_Controller, req)
  println("Photos_Controller::destroy for DELETE")
  "Destroying photos"
end
