# Handling file uploads

Genie has built-in support for working with file uploads. The collection of uploaded files (as `POST` variables) can be accessed through the `Requests.filespayload` method. Or, we can retrieve the data corresponding to a given file form input by using `Requests.filespayload(key)` -- where `key` is the name of the file input in the form.

In the following snippet we configure two routes in the root of the app (`/`): the first route, handling `GET` requests, displays an upload form. The second route, handling `POST` requests, processes the uploads, generating a file from the uploaded data, saving it, and displaying the file stats.

### Example

```julia
using Genie, Genie.Router, Genie.Renderer, Genie.Requests

form = """
<form action="/" method="POST" enctype="multipart/form-data">
  <input type="file" name="yourfile" /><br/>
  <input type="submit" value="Submit" />
</form>
"""

route("/") do
  html(form)
end

route("/", method = POST) do
  if infilespayload(:yourfile)
    download(filespayload(:yourfile))

    stat(filename(filespayload(:yourfile)))
  else
    "No file uploaded"
  end
end

up()
```

Upon uploading a file and submitting the form, our app will display the file's stats.
