type Books_Controller <: Jinnie_Controller
end

function index(Books_Controller, req) 
  @show req
  "Check out this list of awesome books"
end