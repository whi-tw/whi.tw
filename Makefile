export DEST_DIR := build/
export HUGO_BASEURL ?= http://127.0.0.1/ell/

.PHONY: all test clean build
all: test build

ruby_deps: Gemfile Gemfile.lock
	bundle install

test: ruby_deps
	bundle exec mdl src/content

build: ruby_deps src/config.toml src/keybase.txt
	make -wC src build
	bundle exec ruby scripts/cspolicy.rb ${DEST_DIR}

build-preview: ruby_deps src/config.toml src/keybase.txt
	make -wC src build-preview
	bundle exec ruby scripts/cspolicy.rb ${DEST_DIR}

serve:
	make -wC src serve

clean:
	@rm -rf ${DEST_DIR}
