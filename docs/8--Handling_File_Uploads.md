# Handling file uploads

Genie has built-in support for working with file uploads. The collection of uploaded files (as `POST` variables) can be accessed through the `Requests.filespayload` method. Or, we can retrieve the data from a certain variable `key` by using `Requests.filespayload(key)`.

In this snippet we configure to routes in the root of the app (`/`): the first route, handling `GET` requests, displays an upload form. The second route, handling `POST` requests, processes the uploads, generating a file from the upload data, saving it, and displaying file stats.

```julia
using Genie, Genie.Router, Genie.Renderer, Genie.Requests

form = """
<form action="/" method="POST" enctype="multipart/form-data">
  <input type="file" name="fileupload" /><br/>
  <input type="submit" value="Submit" />
</form>
"""

route("/") do
  html(form)
end

route("/", method = POST) do
  if haskey(filespayload(), "fileupload")
    filename = "__" * filespayload("fileupload").name
    write(filename, IOBuffer(filespayload("fileupload").data))

    return stat(filename) |> string
  end

  "No file uploaded"
end

startup()
```

Upon uploading a file and submitting the form, our app will display file stats, similar to `StatStruct(mode=0o100644, size=268579)`.

