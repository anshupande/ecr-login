DEV_VER=0.1

default: compile

install-deps:
	go get github.com/tools/godep
	go get -u github.com/jteeuwen/go-bindata/...
	godep restore

install-test-deps:
	go get -u github.com/golang/lint/golint
	go get golang.org/x/tools/cmd/cover
	go get github.com/onsi/ginkgo/ginkgo
	go get github.com/onsi/gomega

test:
	make install-deps install-test-deps
	go vet ./...
	golint ./...
	ginkgo -r -trace -failFast -v --cover --randomizeAllSpecs --randomizeSuites -p
	echo "" && for i in $$(ls **/*.coverprofile); do echo "$${i}" && go tool cover -func=$${i} && echo ""; done
	echo "" && for i in $$(ls **/**/*.coverprofile); do echo "$${i}" && go tool cover -func=$${i} && echo ""; done

# Make compilation depend on the docker dev container
# Run the build in the dev container leaving the artifact on completion
# Use run-dev to get an interactive session
compile: dev
	@echo "Compiling ecr-login ..."
	@grep -q docker /proc/1/cgroup ; \
	if [ $$? -eq 0 ]; then go build -a -installsuffix cgo ecr-login.go ; \
	else \
		docker run -i --rm --net host -v ~/.bash_history-ecr-login:/root/.bash_history -v `pwd`:/go/src/github.com/behance/ecr-login -w /go/src/github.com/behance/ecr-login -e version=0.0.1  -e CGO_ENABLED=0 -e GOOS=linux behance/ecr-login:dev go build -a -installsuffix cgo ecr-login.go ; \
        fi

build-container: compile
	@echo "Building ecr-login container ..."
	@grep -q docker /proc/1/cgroup ; \
	if [ $$? -ne 0 ]; then \
		docker build --tag behance/ecr-login:`git rev-parse HEAD` .; \
	else \
		echo "You're in a docker container. Leave to run docker" ;\
	fi

upload-current:
	make build-container
	docker push behance/ecr-login:`git rev-parse HEAD`_`date +%Y%m%d`
	docker tag behance/ecr-login:`git rev-parse HEAD`_`date +%Y%m%d` behance/ecr-login:latest
	docker push behance/ecr-login:latest

build: install-deps compile

# build the docker dev container if it doesn't exists
dev:
	@grep -q docker  /proc/1/cgroup ; \
        if [ $$? -ne 0 ]; then \
	  (docker images | grep 'ecr-login' | grep -q dev) || \
	  docker build -f Dockerfile-dev -t behance/ecr-login:dev . ; \
	fi

# run a shell in the docker dev environment, mounting this directory and establishing bash_history in the container instance
run-dev: dev
#       save bash history in-between runs...
	@if [ ! -f ~/.bash_history-ecr-login ]; then touch ~/.bash_history-ecr-login; fi
#       mount the current directory into the dev build
	docker run -i --rm --net host -v ~/.bash_history-ecr-login:/root/.bash_history -v `pwd`:/go/src/github.com/behance/ecr-login -w /go/src/github.com/behance/ecr-login -t behance/ecr-login:dev bash

# use the built in (to alpine) ca-certificates and update-ca-certificates
certificates: dev
	docker run -i --rm  -v ~/.bash_history-ecr-login:/root/.bash_history -v `pwd`:/go/src/github.com/behance/ecr-login -w /go/src/github.com/behance/ecr-login behance/ecr-login:dev bash -c 'update-ca-certificates && cp /etc/ssl/certs/ca-certificates.crt certs/'

