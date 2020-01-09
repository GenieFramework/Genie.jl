# Deploying Genie apps with Heroku Buildpacks

This tutorial shows how to host a Julia/Genie app using a Heroku Buildpack.

## Prerequesites

This guide assumes you have a Heroku account and are signed into the Heroku CLI. [Information on how to setup the Heroku CLI is available here](https://devcenter.heroku.com/articles/heroku-cli).

## The application

In order to try the deployment, you will need a sample application. Either pick one of yours or clone this sample one, as indicated next.

### All Steps (in easy copy-paste format):

Customize your `HEROKU_APP_NAME` to something unique:

```sh
HEROKU_APP_NAME=my-app-name
```

Clone a sample app if needed:

```sh
git clone https://github.com/milesfrain/GenieOnHeroku.git
```

Go into the app's folder:

```sh
cd GenieOnHeroku
```

And create a Heroku app:

```sh
heroku create $HEROKU_APP_NAME --buildpack https://github.com/Optomatica/heroku-buildpack-julia.git
```

Push the newly created app to Heroku:

```sh
git push heroku master
```

Now you can open the app in the browser:

```sh
heroku open -a $HEROKU_APP_NAME
```

If you need to check the logs:

```sh
heroku logs -tail -a $HEROKU_APP_NAME
```

### Steps with more detailed descriptions

#### Select an app name

```sh
HEROKU_APP_NAME=my-app-name
```

This must be unique among all Heroku projects, and is part of the url where your project is hosted (e.g. https://my-app-name.herokuapp.com/).

If the name is not unique, you will see this error at the `heroku create` step.

```sh
Creating ⬢ my-app-name... !
 ▸    Name my-app-name is already taken
```

#### Clone an example project

```sh
git clone https://github.com/milesfrain/GenieOnHeroku.git
cd GenieOnHeroku
```

You may also point to your own project, but it must be a git repo.

A `Procfile` in the root contains the launch command to load your app.
The contents of the `Procfile` for this project is this single line:

```sh
web: julia --project src/app.jl $PORT
```

You may edit the `Procfile` to point to your own project's launch script. (for example `src/my_app_launch_file.jl` instead of `src/app.jl`),
but be sure to take into account the dynamically changing `$PORT` environment variable which is set by Heroku.

If you're deploying a standard Genie application built with `Genie.newapp`, the launch script will be `bin/server`. Genie will automatically pick the `$PORT` number from the environment.

#### Create a Heroku project

```sh
heroku create $HEROKU_APP_NAME --buildpack https://github.com/Optomatica/heroku-buildpack-julia.git
```

This creates a project on the Heroku platform, which includes a separate git repository.

This `heroku` repository is added to the list of tracked repositories and can be observed with `git remote -v`.

```sh
heroku  https://git.heroku.com/my-app-name.git (fetch)
heroku  https://git.heroku.com/my-app-name.git (push)
origin  https://github.com/milesfrain/GenieOnHeroku.git (fetch)
origin  https://github.com/milesfrain/GenieOnHeroku.git (push)
```

We are using a buildpack for Julia. This runs many of the common deployment operations required for Julia projects.
It relies on the directory layout found in the example project, with `Project.toml`, `Manifest.toml` in the root,
and all Julia code in the `src` directory.

#### Deploy your app

```sh
git push heroku master
```

This pushes your current branch of your local repo to the `heroku` remote repo's `master` branch.

Heroku will automatically execute the commands described in the Julia buildpack and Procfile of this latest push.

You must push to the heroku `master` branch to trigger an automated deploy.

#### Open your app's webpage

```sh
heroku open -a $HEROKU_APP_NAME
```

This is a convenience command to open your app's webpage in your browser.

The webpage is: `https://$HEROKU_APP_NAME.herokuapp.com/`

For example: <https://my-app-name.herokuapp.com/>

#### View app logs

```sh
heroku logs -tail -a $HEROKU_APP_NAME
```

This is another convenience command to launch a log viewer that remains open to show the latest status of your app.

The `println` statements from Julia will also appear here.

Exit this viewer with `Ctrl-C`.

Logs can also be viewed from the Heroku web dashboard.
For example: <https://dashboard.heroku.com/apps/my-app-name/logs>

### Deploy app updates changes

To deploy any changes made to your app, simply commit those changes locally, and re-push to heroku.

```sh
<make changes>
git commit -am "my commit message"
git push heroku master
```
