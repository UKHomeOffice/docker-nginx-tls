
NAME=nginx-tls
AUTHOR=gambol99

.PHONY: build test demo

default: build

build:
	sudo docker build -t ${AUTHOR}/${NAME} .

demo:
	sudo docker run -ti  --name nginx-tls --rm -v ${PWD}/tests:/etc/secrets ${AUTHOR}/${NAME} /run.sh -p 443:127.0.0.1:80:demo.example.com

test:
	sudo docker run -ti --rm -v ${PWD}/tests:/etc/secrets --entrypoint=/bin/bash ${AUTHOR}/${NAME}
