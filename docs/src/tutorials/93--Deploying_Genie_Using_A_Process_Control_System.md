# Deploying Genie apps using:  A Process Control System

This tutorial shows how to host a Julia/Genie app using process control system. We using `supervisor`  for this tutorial.

## Prerequisites

Install `supervisor` in system. If you not sure how to install you can find the suitable command from [here](https://command-not-found.com/supervisord)  or you can [refer to official website](http://supervisord.org/)

## The application

We assume that a Genie app has been developed and is ready for deployment and that it is hosted as a project on a git repository.

For example, the app `MyGenieApp` generated through `Genie.Generator.newapp("MyGenieApp")` being hosted at
`github.com/user/MyGenieApp`.

The scripts presented in this tutorial are for Ubuntu 20.04.

## Install and run the Genie app on the server

Access the server:

```shell
ssh -i "ssh-key-for-instance.pem" user@123.123.123.123
```

Install Julia if not present. Then make the clone:

```shell
git clone github.com/user/MyGenieApp
cd MyGenieAp
```

Install the app as any other Julia project:

```shell
julia
] activate .
pkg> instantiate
exit()
```

In order to launch the app using `supervisor` you have to create `genie-supervisor.conf` file or you can name it something else with file name ending `.conf` as extension at project directory path.


```shell
[program:genie-application]
process_name=%(program_name)s_%(process_num)02d
command= ./bin/server
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
numprocs=1
redirect_stderr=true
stdout_logfile=/var/log/genie-application.log
stopwaitsecs=3600
```

Now application is almost ready to start just need to configure [the secret token](https://genieframework.github.io/Genie.jl/dev/API/secrets.html#Genie.Secrets.secret_token). Go inse the project directory and execute following command. It will generate `secrets.jl` insie `config/secrets.jl` file and if it exeists then it will update with new token string.

```sh
julia --project=. --banner=no --eval="using Pkg; using Genie; Genie.Generator.write_secrets_file()"
```


Then set the `GENIE_ENV` environment variable to `prod`:

```shell
export GENIE_ENV=prod
```

To launch the app few things need to do before starting process control.

Create symbolic link to supervisor config directory
```shell
cd /etc/supervisor/conf.d/
sudo ln -s /PATH TO THE SUPERVISOR.CONF FILE
sudo /etc/init.d/supervisor reload
```


### Few assumption about installation instruction
- In this tutorial above configuration is done at `Debian` or `Ubutu` server and tested well
- `GENIE_ENV=prod` should be exported before you run the application else it will take default `GENIE_ENV` environment


### If thing not working then you may check following things.

(1) check the `sudo systemctl status supervisor.service` service is working or not. if not working then you can start and enable for the start up using following command

```shell
sudo systemctl enable supervisor.service
sudo systemctl start supervisor.service
```

and then check if status is active or still has any issue.

(2) You can check the application log by tail to log file as bellow

```shell
tail -f /var/log/genie-application.log
```

in this log you will find the genie logs.

(3) Make sure whatever port you used inside `GENIE_ENV` config file at `server_port` must be open in  at firewall and no other process is bind to it.

Check weather the any process is running at port 80 for an example use following command

```shell
sudo lsof -t -i:80
```

If you want to kill the process which is running at port 80 you can use single liner magic command

```shell
if sudo lsof -t -i:80; then sudo kill -9 $(sudo lsof -t -i:80); fi
```