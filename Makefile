HUGO_VERSION := 0.59.1
export DEST_DIR := build/

.PHONY: all test clean build
all: test build

ruby_deps: Gemfile Gemfile.lock
	bundle install

test: ruby_deps
	bundle exec mdl src/content

build: ruby_deps src/config.toml src/keybase.txt
	make -wC src
	bundle exec ruby scripts/cspolicy.rb ${DEST_DIR}

clean:
	@rm -rf ${DEST_DIR}
