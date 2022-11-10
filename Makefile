preview:
	hugo server

build:
//	rm -rf public && hugo
	rm -rf public && hugo -v3

deploy: build
	aws s3 sync --delete public/ s3://dan.carley.co/
