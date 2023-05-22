export DEST_DIR := $(abspath ./build/)
export BASEURL ?= http://127.0.0.1
export HUGO_BASEURL ?= http://127.0.0.1/ell/

.PHONY: all test clean build
all: test build

$(DEST_DIR):
	mkdir -p $(DEST_DIR)

ruby_deps: Gemfile Gemfile.lock
	bundle install

test: ruby_deps
	bundle exec mdl src/content

build: $(DEST_DIR) ruby_deps src/config.toml src/keybase.txt src/zshrc.erb
	make -wC src build

build-preview: $(DEST_DIR) ruby_deps src/config.toml src/keybase.txt src/zshrc.erb
	make -wC src build-preview

serve:
	make -wC src serve

clean:
	@rm -rf $(DEST_DIR)
