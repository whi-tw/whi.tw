#!/usr/bin/env ruby
# frozen_string_literal: true

require 'nokogiri'
require 'digest'

DEFAULT_PAGE_CSP = [
  'default-src \'none\'',
  'font-src \'self\' https://fonts.gstatic.com',
  'img-src https:'
].freeze

def get_scripts(path)
  sources = []
  shas = []
  html = File.open(path, 'r') { |f| Nokogiri::HTML(f) }
  html.xpath('//script').each do |script|
    unless script['src'].nil?
      uri = URI.parse(script['src'])
      sources.push("#{uri.scheme}://#{uri.host}")
    end
    script.text.empty? || shas.push("sha256-#{Digest::SHA256.base64digest(script.text)}")
  end
  "#{sources.uniq.join(' ')} #{shas.uniq.map { |s| "'#{s}'"}.join(' ')}".rstrip
end

def get_styles(path)
  html = File.open(path, 'r') { |f| Nokogiri::HTML(f) }
  sources = html.xpath('//link[@rel="stylesheet"]/@href').to_a.map { |s| "#{URI.parse(s).scheme}://#{URI.parse(s).host}"}
  shas = []
  html.xpath('//style').each do |style|
    style.text.empty? || shas.push("sha256-#{Digest::SHA256.base64digest(style.text)}")
  end
  "'unsafe-inline' #{sources.uniq.join(' ')}".rstrip #  #{shas.uniq.map{|s| "'#{s}'"}.join(' ')}".rstrip
end

def file_csp(file)
  csp = DEFAULT_PAGE_CSP.dup
  scripts = get_scripts(file)
  scripts.empty? || csp.push("script-src #{scripts}")
  #csp.push(get_scripts(file))
  csp.push("style-src #{get_styles(file)}")
  [
    {
      url: "/#{file.split('/').drop(2).join('/')}",
      csp: csp.join('; ')
    },
    {
       url: "/#{file.split('/').drop(2).join('/').split('/index.html')[0]}",
       csp: csp.join('; ')
    }
  ]
end

def gen_csp_headers(page_policies)
  chunks = [%(/*
  X-Frame-Options: DENY
  X-XSS-Protection: 1; mode=block
  Referrer-Policy: no-referrer-when-downgrade
)]
  page_policies.each do |policy|
    chunks.push(%(#{policy[:url]}
  Content-Security-Policy: #{policy[:csp]}))
  end
  chunks
end

DESTINATION = ARGV[0]
HTML_FILES = Dir["#{DESTINATION}/**/*.html"]

page_policies = []
HTML_FILES.each do |path|
  page_policies.concat file_csp(path)
end

File.open('build/_headers', 'w') do |outfile|
  outfile.puts(gen_csp_headers(page_policies))
end