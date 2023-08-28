.DEFAULT_GOAL :=all

all:
	docker build -t pospelov_build .
	docker run -it --rm -v `pwd`:/opt --user `id -u`:`id -g` -v /etc/passwd:/etc/passwd:ro -v /etc/group:/etc/group:ro pospelov_build
clean:
	rm -rf pdfalto
