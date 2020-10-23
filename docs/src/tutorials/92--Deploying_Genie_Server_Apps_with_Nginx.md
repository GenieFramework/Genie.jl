# Deploying Genie apps with Heroku Buildpacks

This tutorial shows how to host a Julia/Genie app on with Nginx.

## Prerequisites

To expose the app over the internet, one needs access to a server. This can be a local machine or a cloud instance such as AWS EC2 or a Google Cloud Compute Engine for example).

If using a local server, a static IP is needed to ensure continuous access to the app. Internet service provider generally charge a fee for such extra service.

## The application

We assume that a Genie app has been developed and is ready for deployment and that it is hosted as a project on a git repository.

For example, the app `MyGenieApp` generated through `Genie.newapp("MyGenieApp")` being hosted at `github.com/user/MyGenieApp`.

## All Steps

Assuming the server in running Ubuntu.

### Install the and run the Genie app on the server.

Access the server:

```
ssh -i "ssh-key-for-instance.pem" user@123.123.123.123
```

Install Julia if not present. Then make the clone:

```
git clone github.com/user/MyGenieApp
cd MyGenieAp
```

Install the app as any other Julia project:

```
julia
] activate .
Pkg> instantiate
exit()
```

In order to launch the app and exit the console without shutting down the app, we will launch it from a new screen

```
screen -S genie
```

Then set the GENIE_ENV environment variable to `prod`:

```
export GENIE_ENV=prod
```

Launch the app:

```
./bin/server
```

Now the Genie app should be running on the server and be accessible at the following address: `123.123.123.123:8000` (if port 8000 has been open - see instance security settings). Note that only raw content will be returned as the `prod` Genie environments doesn't serve the static content (see the `Settings` option `server_handle_static_file` in `config/env/prod.jl`). Static content will be handled by nginx. We can now detach from the `genie` screen used to launch the app (Ctl+A d).

### Install nginx server

Nginx server will be used as a reverse proxy. It will listen requests made on port 80 (HTTP) and redirect traffic to the Genie app running on port 8000 (default Genie setting that can be changed).

Nginx will also be used to serve the app static files, that is, the content under the `./public` folder.

Finally, it can as well handle HTTPS requests, which will also be redirected to the Genie app listening on port 8000.

Installation:

```
sudo apt-get update
sudo apt-get install nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

A configuration file then needs to to be created to indicate on which port to listen (80 for HTTP) and to which port to redirect the traffic (8000 for default Genie config).

Config is created in folder `/etc/nginx/sites-available`: `sudo nano my-genie-app`.
Put the following content in `my-genie-app`:

```
server {
  listen 80;
  listen [::]:80;

  server_name   test.com;
  root          /home/ubuntu/MyGenieApp/public;
  index         welcome.html;

  location / {
      proxy_pass http://localhost:8000/;
  }

  location /css/genie {
      proxy_pass http://localhost:8000/;
  }
  location /img/genie {
      proxy_pass http://localhost:8000/;
  }
  location /js/genie {
      proxy_pass http://localhost:8000/;
  }
}
```

- `server_name`: refers to the web domain to be used. It can be put to an arbitrary name if the app is only to be served directly from the server public IP.
- `root`: points to the `public` subfolder where the genie app was cloned.
- `index`: refers to the site index (the landing page).
- The various `location` following the initial proxy to the genie app are used to indicate static content folders to be served by nginx. These are needed when the `server_handle_static_file` is set to `false` in the Genie app settings.

To make that config effective, it needs to be present in `sites-enabled`. The `default` config can be removed.

```
sudo ln -s /etc/nginx/sites-available/my-genie-app /etc/nginx/sites-enabled/my-genie-app
```

Then restart the server to make changes effective:

```
 sudo systemctl restart nginx
 ```

### Enable HTTPS

To enable HTTP, a site-certificate will be needed for the domain on which the site will be served.
A practical approach is to use the utilities provided by [certbot](https://certbot.eff.org/).

Following provived instructions for nginx on Ubuntu 20.04:

```
sudo snap install core; sudo snap refresh core
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
```

Then, using certbot utility, a certificate will be generated and appropriate modification to nginx config will be brought to handle support for HTTPS:

```
sudo certbot --nginx
````

Note that this steps will check for ownernship of the `test.com` domain mentionned in the nginx config file. For that validation to succeed, it requires to have the `A` record for the domain set to `123.123.123.123`.
