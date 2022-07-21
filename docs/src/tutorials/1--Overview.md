# Welcome to Genie

## The Highly Productive Web Framework for Julia

Genie is a full stack web framework for the Julia programming language. Genie's goals are: excellent developer
productivity, great run-time performance, and best practices and security by default.

The Genie web framework follows in the footsteps of mainstream full stack web frameworks like Ruby on Rails and Django,
while staying 100% true to its Julia roots. Genie's architecture and development is inspired by the best features present in other
frameworks, but not by their design. Genie takes a no-magic no-nonsense approach by doing things the Julia way:
`Controllers` are plain Julia modules, `Models` leverage types and multiple dispatch, Genie apps are nothing but Julia
projects, versioning and dependency management is provided by Julia's own `Pkg`, and code loading and reloading is automatically
set up with `Revise`.

Genie also takes inspiration from Julia's "start simple, grow as needed" philosophy, by allowing developers to bootstrap
an app in the REPL or in a notebook, or easily create web services and APIs with just a few lines of code.

As the projects grow more complex, Genie allows adding progressively more structure, by exposing a micro-framework
which offers features like powerful routing, flexible logging, support for environments, view templates, etc.

If database persistence is needed, support for Genie's ORM, SearchLight, can be added at any time. Finally, the full MVC
structure can be used in order to develop and maintain more complex, end-to-end, web applications.
