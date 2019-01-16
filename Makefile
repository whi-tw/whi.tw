.PHONY: all test
all: install_prereqs test build

install_prereqs:
	npm install markdownlint-cli

test:
	node_modules/.bin/markdownlint src/content

build: src/amp.toml src/config.toml src/keybase.txt
	make -wC src
