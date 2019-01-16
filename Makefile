HUGO_VERSION:=0.53

.PHONY: all travis_preinstall install_hugo install_markdownlint test
all: install_markdownlint test build

travis_preinstall: install_hugo install_markdownlint

install_hugo:
	wget https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_Linux-64bit.tar.gz
	sudo tar xzf hugo_${HUGO_VERSION}_Linux-64bit.tar.gz -C /usr/local/bin/ hugo
	sudo chmod +x /usr/local/bin/hugo
	rm hugo_${HUGO_VERSION}_Linux-64bit.tar.gz

install_markdownlint:
	npm install markdownlint-cli

test:
	node_modules/.bin/markdownlint src/content

build: src/amp.toml src/config.toml src/keybase.txt
	make -wC src

gh_pages_cname:
	echo "${DOMAIN}" > build/CNAME
