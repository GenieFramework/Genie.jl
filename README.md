<div align="center">
  <a href="https://genieframework.com/">
    <img
      src="docs/content/img/genie-lightblue.svg"
      alt="Genie Logo"
      height="64"
    />
  </a>
  <br />
  <p>
    <h3>
      <b>
        Genie.jl
      </b>
    </h3>
  </p>
  <p>
    <b> 🧞 The highly productive Julia web framework
    </b>
  </p>

  <p>

[![Docs](https://img.shields.io/badge/genie-docs-greenyellow)](https://www.genieframework.com/docs/) [![current status](https://img.shields.io/badge/julia%20support-v1.6%20and%20up-dark%20green)](https://github.com/GenieFramework/Genie.jl/blob/173d8e3deb47f20b3f8b4e5b12da6bf4c59f3370/Project.toml#L53) [![Website](https://img.shields.io/website?url=https%3A%2F%2Fgenieframework.com&logo=genie)](https://www.genieframework.com/) [![Tests](https://img.shields.io/badge/build-passing-green)](https://github.com/GenieFramework/Genie.jl/actions) [![Genie Downloads](https://shields.io/endpoint?url=https://pkgs.genieframework.com/api/v1/badge/Genie)](https://pkgs.genieframework.com?packages=Genie) [![Tweet](https://img.shields.io/twitter/url?url=https%3A%2F%2Fgithub.com%2FGenieFramework%2FGenie.jl)](https://twitter.com/GenieMVC)

  </p>
  <p>
    <sub>
      Built with ❤︎ by
      <a href="https://github.com/GenieFramework/Genie.jl/graphs/contributors">
        contributors
      </a>
    </sub>
  </p>
  <br />
  <p>
    <a href="https://www.genieframework.com/">
      <img
        src="docs/content/img/genie.gif"
        alt="Screenshot"
        width="100%"
      />
    </a>
  </p>
</div>

<p style="font-family:verdana;font-size:80%;margin-bottom:4%" align="center">
<u>Julia data dashboards powered by Genie</u>
</p>

<p align="center">
  Genie is a full-stack web framework that provides a streamlined and efficient workflow for developing modern web applications. It builds on Julia's strengths (high-level, high-performance, dynamic, JIT compiled), exposing a rich API and a powerful toolset for productive web development.
</p>

#### **Need Help?** Reach out on our social media channels.

[![Chat on Discord](https://img.shields.io/badge/chat-Discord-7289DA?logo=discord)](https://discord.com/invite/9zyZbD6J7H) [![Chat on Gitter](https://img.shields.io/badge/gitter-chat-red)](https://gitter.im/essenciary/Genie.jl) [![Discuss on GitHub](https://img.shields.io/badge/discussions-GitHub-333333?logo=github)](https://github.com/GenieFramework/Genie.jl/discussions)

<hr>

<details open>
  <summary><b>Table of contents</b></summary>

---

- [**Made With Genie**](#made-with-genie)
- [**Community Curated Resources**](#community-curated-resources)
- [**Community Mentions**](#community-mentions)
- [**Contributing**](#contributing)
- [**Special Credits**](#special-credits)
- [**License**](#license)

---

</details>

### **Features**

🛠**Genie Router:** Genie has a really powerful
💪 `Router`. Matching web requests to functions, extracting and setting up the request's variables and the execution environment, and invoking the response methods. Features include:

- Static, Dynamic, Named routing
- Routing parameters
- Linking routes
- Route management (Listing, Deleting, Modifying) support
- Routing methods (`GET`, `POST`, `PUT`, `PATCH`, `DELETE`, `OPTIONS`)
- and more ...

```julia
# Genie Hello World!
# As simple as Hello
using Genie
route("/hello") do
    "Welcome to Genie!"
end

# Powerful high-performance HTML view templates
using Genie.Renderer.Html
route("/html") do
    h1("Welcome to Genie!") |> html
end

# JSON rendering built in
using Genie.Renderer.Json
route("/json") do
    (:greeting => "Welcome to Genie!") |> json
end

# Start the app!
up(8888)
```

🔌 **WebSocket:** Genie provides a powerful workflow for client-server communication over websockets

```julia-repl
julia> using Genie, Genie.Router

julia> channel("/foo/bar") do
         # process request
       end
[WS] /foo/bar => #1 | :foo_bar
```

📃 **Templating:** Built-in templates support for `HTML`, `JSON`, `Markdown`, `JavaScript` views.

🔐 **Authentication:** Easy to add database backed authentication for restricted area of a website.

```julia-repl
julia> using Pkg

julia> Pkg.add("GenieAuthentication") # adding authentication plugin

julia> using GenieAuthentication

julia> GenieAuthentication.install(@__DIR__)
```

⏰ **Tasks:** Tasks allow you to perform various operations and hook them with crons jobs for automation

```julia
module S3DBTask
# ... hidden code

  """
  Downloads S3 files to local disk.
  Populate the database from CSV file
  """
  function runtask()
    mktempdir() do directory
      @info "Path of directory" directory
      # download record file
      download(RECORD_URL)

      # unzip file
      unzip(directory)

      # dump to database
      dbdump(directory)
    end
  end

# ... more hidden code
end
```

```shell
$ bin/runtask S3DBTask
```

📦 **Plugin Ecosystem:** Explore plugins built by the community such as [GenieAuthentication](https://github.com/GenieFramework/GenieAuthentication.jl), [GenieAutoreload](https://github.com/GenieFramework/GenieAutoreload.jl), [GenieAuthorisation](https://github.com/GenieFramework/GenieAuthorisation.jl), and more

🗃️ **ORM Support:** Explore [SearchLight](https://github.com/GenieFramework/SearchLight.jl) a complete ORM solution for Genie, supporting Postgres, MySQL, SQLite and other adapters

```julia

function search(user_names, regions, startdate, enddate)
# ... hidden code

  where_filters = SQLWhereEntity[
      SQLWhereExpression("lower(user_name) IN ( $(repeat("?,", length(user_names))[1:end-1] ) )", user_names),
      SQLWhereExpression("date >= ? AND date <= ?", startdate, enddate)
  ]

  SearchLight.find(UserRecord, where_filters, order=["record.date"])

# ... more hidden code
end
```

- `Database Migrations`
```julia
module CreateTableRecord

import SearchLight.Migrations: create_table, column, primary_key, add_index, drop_table

function up()
  create_table(:record) do
    [
      primary_key()
      column(:user_uuid, :string, limit = 100)
      column(:user_name, :string, limit = 100)
      column(:status, :integer, limit = 4)
      column(:region, :string, limit = 20)
      column(:date_of_birth, :string, limit = 100)
    ]
  end

  add_index(:record, :user_uuid)
  add_index(:record, :user_name)
  add_index(:record, :region)
  add_index(:record, :date_of_birth)
end

function down()
  drop_table(:record)
end

end
```

* `Model Validations`

📝 More Genie features like:
* `Files Uploads`

```julia
route("/", method = POST) do
  if infilespayload(:yourfile)
    write(filespayload(:yourfile))

    stat(filename(filespayload(:yourfile)))
  else
    "No file uploaded"
  end
end
```

* `Logging` | `Caching` | `Cookies and Sessions` | `Docker, Heroku, JuliaHub, etc Integrations` | `Genie Deploy`
* To explore more features check [Genie Documentation](https://www.genieframework.com/docs/genie/tutorials/Overview.html) 🏃‍♂️🏃‍♀️

## **Made With Genie**

- Packages/Libraries:

  * Stipple: [Stipple is a reactive UI library for building interactive data applications in pure Julia](https://github.com/GenieFramework/Stipple.jl)

  * StippleUI: [StippleUI is a library of reactive UI elements for Stipple.jl](https://github.com/GenieFramework/StippleUI.jl)

  * StipplePlotly: [StipplePlotly is a plotting library for Stipple.jl](https://github.com/GenieFramework/StipplePlotly.jl)

  * StippleCharts: [StippleCharts is yet another plotting/charting solution for Stipple.jl](https://github.com/GenieFramework/StippleCharts.jl)

- Demo Apps:
  * Julia [package download app](https://github.com/GenieFramework/PkgVizBoard) ([data](https://discourse.julialang.org/t/announcing-package-download-stats/69073) provided by Julia Lang)
  * [German Credit visualization](0https://github.com/GenieFramework/Stipple-Demo-GermanCredits) dashboard
  * [Iris flowers dataset k-means clustering](https://github.com/GenieFramework/Stipple-Demo-IrisClustering) dashboard

## **Community Curated Resources**

* [![Awesome Genie](https://cdn.rawgit.com/sindresorhus/awesome/d7305f38d29fed78fa85652e3a63e154dd8e8829/media/badge.svg) **Awesome Genie**](https://github.com/AbhimanyuAryan/genie-awesome): A curated list of awesome things related to Julia's Web framework Genie.

## **Community Mentions**

* [6 Julia Frameworks to Create Desktop GUI’s 🖥 and Web Apps](https://logankilpatrick.medium.com/6-julia-frameworks-to-create-desktop-guis-and-web-apps-9ae1a941f115) by Logan Kilpatrick

* [12 Best Julia web frameworks](https://www.dunebook.com/julia-web-framework/) by Olanrewaju Olakunle

* [What are the best web frameworks for Julia programming language?](https://qr.ae/pG6Zdn) by Morgane Alinaï

## **Contributing**

Please contribute using [GitHub Flow](https://guides.github.com/introduction/flow). Create a branch, add commits, and [open a pull request](https://github.com/genieframework/genie.jl/compare).

Please read [`CONTRIBUTING`](CONTRIBUTING.md) for details on our [`CODE OF CONDUCT`](CODE_OF_CONDUCT.md), and the process for submitting pull requests to us.

## **Special Credits**

* The awesome Genie logo was designed by Alvaro Casanova

* Hoppscoth for readme structure template

* Genie uses a multitude of packages that have been kindly contributed by the Julia community

## **License**

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT) - see the [`LICENSE`](https://github.com/GenieFramework/Genie.jl/blob/master/LICENSE.md) file for details.

<p>⭐ If you enjoy this project please consider starring the 🧞 <b>Genie.jl</b> GitHub repo. It will help us fund our open source projects.</p>
