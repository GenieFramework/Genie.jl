# Welcome to Genie

## The Highly Productive Web Framework for Julia

Genie is a full stack web framework for the Julia programming language. Genie's goals are developer productivity, high run-time performance, and security by default.

The Genie web framework follows in the footsteps of mainstream full stack web frameworks like Ruby on Rails and Django, while staying 100% true to its Julia roots. Genie's architecture and development is driven by features present in other frameworks, but not by their design. Genie takes a no-magic-no-nonsense approach by doing things the Julia way: `Controllers` are plain Julia modules, `Models` leverage types and multiple dispatch, Genie apps are nothing but Julia projects, or versioning and dependency management is provided by `Pkg`.

Genie also takes inspiration from Julia's "start simple, grow as needed" philosophy, by allowing developers to bootstrap an app in the REPL or in a Jupyter notebook, or create one script REST APIs with just a few lines of code. As the projects grow more complex, Genie allows adding progressively more structure, by exposing a micro-framework which offers features like routing and support for environments (`dev`, `test` and `prod`). If database persistence is needed, support for Genie's ORM, SearchLight, can be added at any time. Finally, full MVC structure can be used in order to drive the development and maintainance of complex, end-to-end, web applications.
