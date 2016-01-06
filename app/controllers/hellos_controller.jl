type Hellos_Controller <: Jinnie_Controller
end

function index(_::Hellos_Controller, req)
	println("Hellos_Controller::index for GET")
	"Listing hellos"
end

function show(_::Hellos_Controller, req)
  println("Hellos_Controller::show for GET")
  "Showing hello"
end

function create(_::Hellos_Controller, req)
	println("Hellos_Controller::create for POST")
	"Creating hellos"
end

function update(_::Hellos_Controller, req)
	println("Hellos_Controller::update for PUT")
	"Updating hellos"
end

function destroy(_::Hellos_Controller, req)
	println("Hellos_Controller::destroy for DELETE")
	"Destroying hellos"
end