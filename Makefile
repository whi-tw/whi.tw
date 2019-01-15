.PHONY: all test
all: install_prereqs test build

install_prereqs:
	npm install markdownlint-cli

test:
	node_modules/.bin/markdownlint src/content

build: src/amp.toml src/config.toml src/keybase.txt
	cd src && hugo -d ../build/ell
	cd src && hugo --config amp.toml -d ../build/ell/amp
	cd src && cp keybase.txt ../build/
