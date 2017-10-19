preview:
	hugo server

build:
	rm -rf public && hugo

deploy: build
	aws s3 sync --delete public/ s3://dan.carley.co/
