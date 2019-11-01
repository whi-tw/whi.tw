HUGO_VERSION:=0.59.1

.PHONY: all test clean
all: test build

node_modules/.bin/markdownlint:
	yarn install --dev

test: node_modules/.bin/markdownlint
	@yarn run lint-content

build: src/config.toml src/keybase.txt
	make -wC src

gh_pages_cname:
	echo "${DOMAIN}" > build/CNAME

clean:
	@rm -rf build
	@rm -rf node_modules
