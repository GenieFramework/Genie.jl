type Photos_Controller <: Jinnie_Controller
end

function index(_::Photos_Controller, req)
  println("Photos_Controller::index for GET")
  "Listing photos"
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
