.PHONY: build-image push-image run

build-image:
	sudo docker build -t gadl/spot-dtwasat .

push-image:
	sudo docker push gadl/spot-dtwasat

run:
	cd .. && sudo docker run -t -i -v $$PWD:/remote gadl/spot-dtwasat /bin/bash
