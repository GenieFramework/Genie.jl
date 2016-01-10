routes =
	quote
		get("/books", :books, :index),
		get(
			"/hellos/new", 
			req -> new(Hellos_Controller(), req)
			),
		get(
				"/hellos/:id", 
				req -> show(Hellos_Controller(), req)
			),
		get(
			"/hellos/:id/edit", 
			req -> edit(Hellos_Controller(), req)
			),
		get( 
			"/hellos", 
			req -> index(Hellos_Controller(), req)
			),
		post(
			"/hellos", 
			req -> create(Hellos_Controller(), req)
			),
		put(
			"/hellos/:id", 
			req -> update(Hellos_Controller(), req)
			),
		delete(
			"/hellos/:id", 
			req -> destroy(Hellos_Controller(), req)
			),
		@resources("photos", [:index, :show, :edit, :create])..., 
		get("/", :welcome, :index)
	end

export routes