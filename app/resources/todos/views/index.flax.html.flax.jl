(vars) -> begin 
Flax.html()  do;[ 
	Flax.head()  
	Flax.body()  do;[ 
		Flax.div(:class => "row")  do;[ 
			Flax.ul(:class => "list-group")  do;[ 
							 mapreduce(*, vars[:todos]) do (todo)  
				Flax.li(:class => "list-group-item")  do;[ 
					 todo.title  

 				]end 
 
				 end  

 			]end 

 		]end 

 	]end 

 ]end 
end