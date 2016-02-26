FROM golang:1.6-onbuild

ADD certs/ca-certificates.crt /etc/ssl/certs/
ADD templates /
