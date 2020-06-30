# Frontend assets

Genie makes use of Yarn and Webpack to compile and serve frontend assets. In fact out of the box a config file making use of Webpack4's most popular features is supplied, as well as Bootstrap4 and jQuey pre-installed. That way you can focus on your web app, taking yet another layer of abstraction away.

As summary:

- production minimizes files, separating CSS from JS
- development uses webpack-dev-server on node port 3000 (relies on inbuilt socket server)
- supported file formats: css, scss, sass, js, coffee
- output is saved to `public/dist` of your Genie app
- pre-configured with Bootstrap4 and jQuery
- supports bundling (chunks and async loading)

## Requirements

** In order for the Genie app to install the asset pipeline the app needs to be created using the `fullstack = true` option, as in: **

```julia
julia> Genie.newapp("MyApp", fullstack = true)
```


You will need NodeJS as well as Yarn to be installed on system. If using Linux, macOS your package manager should easily allow this. Windows please download relevant installer from NodeJS project webpage.

## Installing dependencies

From app directory:

```
yarn install
```

## Development mode

From app directory:

```
yarn run develop
```

Static files will be served via Node server websocket on port 3000. Sourcemaps will be supplied as well, allowing you to easily debug.

Any changes you make to static files will automatically be sent to browser. If working with React/Vue, state of page will be conserved during process. Save time without re-compiling and reloading page.

Genie by default runs in development mode. Hence if using `app/assets/js/application.js` as main entry point, no additional configurations are required.

## Production mode

From app directory:

```
yarn run build
```

This will output minified files to `public/dist` dir of your app, without source maps.

Please run Genie in production mode to serve static assets.

## Considerations

In order to take best advantage of Webpack bundling, it is recommended to serve all static files (images, fonts) via JS `require` calls. Let Webpack optimise bundle.

Lazy-loading is also supported. This means that browser will fetch ressources when required, speeding-up page loads. As an example, consider chat integration via a button. With demo code below, the chat functionality will only be fetched by browser once user clicks button.

```
button.onclick = () => {
  import("./chat").then(chat => {
    chat.init()
  })
}
```

## Minimal Bootstrap integration

Following Webpack philisophy, it is recommended to only load library dependencies when necessary. Nonetheless for Bootstrap to work, one can do as follows:

- under `app/assets/js/application.js`, add `import "bootstrap";`
- create new file `app/assets/css/vendor.scss` and add `@import "~bootstrap/scss/bootstrap.scss";`
- include this new file from `app/assets/js/application.js`, by adding `require("../css/vendor.scss");`
