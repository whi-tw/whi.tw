HUGO_VERSION := 0.59.1
export DEST_DIR := $(shell pwd)/build

.PHONY: all test clean build
all: test build

node_dependencies = node_modules/.bin/markdownlint node_modules/cheerio/lib/cheerio.js
$(node_dependencies): package.json
	yarn install --dev

test: node_modules/.bin/markdownlint
	@yarn run lint-content

build: src/config.toml src/keybase.txt node_modules/cheerio/lib/cheerio.js
	make -wC src
	yarn run generate-cs-policy ${DEST_DIR}

clean:
	@rm -rf ${DEST_DIR}
	@rm -rf node_modules
