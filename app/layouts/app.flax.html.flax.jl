(vars) -> begin 
Flax.html(:lang => "en")  do;[ 
	Flax.head()  do;[ 
					Flax.title()  do;[ 
			"Genie Todo MVC"
 		]end 
 
		Flax.link(:crossorigin => "anonymous", :rel => "stylesheet", :href => "https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css", :integrity => "sha384-BVYiiSIFeK1dGmJRAkycuHAHRg32OmUcww7on3RYdg4Va+PmSTsz/K68vbdEjh4u")  
		Flax.link(:crossorigin => "anonymous", :rel => "stylesheet", :href => "https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap-theme.min.css", :integrity => "sha384-rHyoN1iRsVXV4nD0JutlnGaslCJuC7uwjduW9SVrLvRYooPp2bWYgmgJQIXwl/Sp")  

 	]end 
 
	Flax.body()  do;[ 
			Flax.nav(:class => "navbar navbar-default")  do;[ 
			Flax.div(:class => "container-fluid") 
 		]end 
 
		Flax.div(:class => "container")  do;[ 
			 vars[:yield]  
			 include_template("app/layouts/shared/footer.flax.html")  

 		]end 

 	]end 

 ]end 
end