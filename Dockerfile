FROM scratch

ADD certs/ca-certificates.crt /etc/ssl/certs/
ADD ecr-login /
ADD templates /templates

CMD [ "/ecr-login" ]
