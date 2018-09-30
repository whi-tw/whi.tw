#!/usr/bin/env sh

hugo -b "https://whi.tw/ell" -d public
hugo -b "https://whi.tw/ell/amp" --config amp.toml -d public/amp
