# Welcome to Genie

## The Highly Productive Web Framework for Julia

Genie is a full stack web framework for the Julia programming language. Its goals are developer productivity, high performance, and security by default.

The Genie web framework follows in the footsteps of full stack web frameworks like Ruby on Rails and Django, while staying 100% true to its Julian origin. Genie's architecture and development is driven by features present in other frameworks, but not by their design. Genie takes a no-magic no-nonsense approach by doing things the Julia way: `Controllers` are plain Julia modules, `Models` leverage types and multiple dispatch, Genie apps are nothing but Julia projects, versioning and dependency management is provided by `Pkg`, etc.

Genie also took inspiration from Julia's "start simple, grow as needed" philosophy, by allowing developers to bootstrap an app in the REPL or in a Jupyter notebook, or create one script REST APIs in just a few lines of code. As the projects grow more complex, Genie allows adding progressively more structure, by exposing a micro-framework which offers fundamental features like routing and support for environments (`dev`, `test` and `prod`). If database persistence is needed, support for Genie's ORM, SearchLight, can be added at any time. Finally, full MVC structure can be added in order to sainly drive the development and maintainance of complex web applications.
