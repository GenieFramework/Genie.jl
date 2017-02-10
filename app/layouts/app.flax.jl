using Flax

(vars) -> begin
  html(:lang => "en") do;[
    head() do;[
      title() do
        "Genie ToDo MVC"
      end
      link( :rel          => "stylesheet",
            :href         => "https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css",
            :integrity    => "sha384-BVYiiSIFeK1dGmJRAkycuHAHRg32OmUcww7on3RYdg4Va+PmSTsz/K68vbdEjh4u",
            :crossorigin  => "anonymous")
      link( :rel          => "stylesheet",
            :href         => "https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap-theme.min.css",
            :integrity    => "sha384-rHyoN1iRsVXV4nD0JutlnGaslCJuC7uwjduW9SVrLvRYooPp2bWYgmgJQIXwl/Sp",
            :crossorigin  => "anonymous")
      script( :src          => "https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js",
              :integrity    => "sha384-Tc5IQib027qvyjSMfHjOMaLkfuWVxZxUPnCJA7l2mCWNIpG9mGCD8wGNIcPD7Txa",
              :crossorigin  => "anonymous") do
                ""
      end
    ]end
    body() do;[
      nav(:class => "navbar navbar-default") do;[
        d(:class => "container-fluid") do
          ""
        end
      ]end
      d(:class => "container") do;[
        vars[:yield]
        include("app/layouts/shared/footer.flax.jl")(nothing)
      ]end
    ]end
  ]
  end |> Flax.doc
end
