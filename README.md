# ecr-login

Login tool for AWS Container Registry.

This is a lightweight golang version of the AWS command-line utility
`aws ecr get-login`, designed to build into a small scratch docker
image.

Can also produce output in other formats using golang templates.

## Installation

See build or docker image below.

## Usage

Login to your AWS Container Registry:

```
$ eval $(./ecr-login)
WARNING: login credentials saved in /Users/ric/.docker/config.json
Login Succeeded
```

Alternatively, you can use the included templates to output docker
config format directly and redirect output to `~/.docker/config.json`
or `~/.dockercfg`:

```
$ TEMPLATE=templates/config.tmpl ./ecr-login
{
        "auths": {
                "https://1234567890.dkr.ecr.us-east-1.amazonaws.com": {
                        "auth": "...",
                        "email": "none"
                }
         }
}
```

In addition to the standard AWS Go SDK environment variables such as AWS_ACCESS_KEY, AWS_REGION, and AWS_SECRET_KEY.  The REGISTRIES variable can be used to specify a non-default registry or multiple comma delimited ECR registries.  When run through a Docker container, this can be especially useful for obtaining credentials on Mesos slaves.

```
docker run --name ecr-login -e "TEMPLATE=templates/dockercfg.tmpl" -e "AWS_REGION=us-east-1" -e "REGISTRIES=012345678901" behance/ecr-login
```

## Systemd example

This is an example of how I use `ecr-login` with systemd units on
CoreOS:

```
[Unit]
Description=Example

[Service]
User=core
Environment=AWS_REGION=us-east-1
ExecStartPre=/bin/bash -c 'eval $(docker run -e AWS_REGION behance/ecr-login)'
ExecStartPre=-/usr/bin/docker rm example
ExecStartPre=/usr/bin/docker pull 1234567890.dkr.ecr.us-east-1.amazonaws.com/example:latest
ExecStart=/usr/bin/docker run --name example 1234567890.dkr.ecr.us-east-1.amazonaws.com/example:latest
ExecStop=/usr/bin/docker stop example
```

## Build from source

```
go build ./ecr-login.go
```

## Docker image

```
version=0.0.1
CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo ecr-login.go
docker build -t behance/ecr-login:${version} .
docker tag -f behance/ecr-login:${version} behance/ecr-login:latest
docker push behance/ecr-login
```
