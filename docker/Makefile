.PHONY: build-image push-image run

build-image:
	sudo docker build -t gadl/satminexp .

push-image:
	sudo docker push gadl/satminexp

run:
	cd ../scripts && sudo docker run -t -i -v $$PWD:/remote gadl/satminexp sh -c 'cd /remote && ./all.sh'
