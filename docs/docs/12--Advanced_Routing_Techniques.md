# Advanced routing techniques

Genie's router can be considered the brain of the app, matching web requests to functions, extracting and setting up the request's variables and the execution environment, and invoking the response methods. Such power is accompanied by a powerful set of features in regards to defining routes. Let's dive into these.

## Basic routing

Starting with the simplest case, we can register "plain" routes by using the `route` method. The method takes as its required arguments the URI pattern and the function that should be invoked in order to provide the response.

## Links to routes

