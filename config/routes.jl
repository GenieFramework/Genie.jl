routes = 
	quote
		(
		root(:package, :index), 
		# get("/books", :books, :index)
		# @resources("products")...,
		# @resources("photos", [:index, :show])...,
		# @resources("habbits", [], [:delete])...,
		# get(
		# 	"/hellos/new", 
		# 	req -> new(Hellos_Controller(), req)
		# 	),
		# get(
		# 	"/hellos/:id", 
		# 	req -> show(Hellos_Controller(), req)
		# 	),
		# get(
		# 	"/hellos/:id/edit", 
		# 	req -> edit(Hellos_Controller(), req)
		# 	),
		# get( 
		# 	"/hellos", 
		# 	req -> index(Hellos_Controller(), req)
		# 	),
		# post(
		# 	"/hellos", 
		# 	req -> create(Hellos_Controller(), req)
		# 	),
		# put(
		# 	"/hellos/:id", 
		# 	req -> update(Hellos_Controller(), req)
		# 	),
		# delete(
		# 	"/hellos/:id", 
		# 	req -> destroy(Hellos_Controller(), req)
		# 	), 
		# get("go", respond("Yeeessooo"))
	)
	end

export routes