using Router

route("/", "todos#TodosController.index")
route("/todos/:id::Int", "todos#TodosController.show", named = :todo_item)
route("/todos/:id::Int/edit", "todos#TodosController.edit")
route("/todos/:id::Int", "todos#TodosController.update", method = POST)
route("/todos/new", "todos#TodosController.new")
route("/todos", "todos#TodosController.create", method = POST)
