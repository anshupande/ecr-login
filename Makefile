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

compile:
#	go-bindata -pkg resources -o resources/bindata.go resources/...
	go build -o ./ecr-login

build-container:
	docker build --tag behance/ecr-login:`git rev-parse HEAD` .

upload-current:
	make build-container
	docker push behance/ecr-login:`git rev-parse HEAD`
	docker tag behance/ecr-login:`git rev-parse HEAD` behance/ecr-login:latest
	docker push behance/ecr-login:latest

build: install-deps compile

dev:
	docker build -f Dockerfile-dev -t behance/ecr-login:dev .

run-dev:
	# save bash history in-between runs...
	if [ ! -f ~/.bash_history-ecr-login ]; then touch ~/.bash_history-ecr-login; fi
	# mount the current directory into the dev build
	docker run -i --rm --net host -v ~/.bash_history-ecr-login:/root/.bash_history -v `pwd`:/go/src/github.com/behance/ecr-login -w /go/src/github.com/behance/ecr-login -t behance/ecr-login:dev bash
