FROM julia:latest

# dependencies
RUN apt-get update && apt-get install -y supervisor

# nginx
RUN apt-get install -y nginx
RUN service nginx start

# user
RUN useradd --create-home --shell /bin/bash genie
USER genie

# supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN mkdir /app
COPY . /app
WORKDIR /app
COPY ./Manifest.toml /app/Manifest.toml
COPY ./Project.toml /app/Project.toml
RUN julia -e "using Pkg; pkg\"activate . \"; pkg\"instantiate\"; pkg\"precompile\"; "

# PORTS
EXPOSE 8000
EXPOSE 80

# start app via supervisor
CMD ["/usr/bin/supervisord"]