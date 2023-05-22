#!/usr/bin/env ruby
# frozen_string_literal: true

require 'nokogiri'
require 'digest'
require 'uri'

REPORT_URI_SUBDOMAIN = 'whitw.report-uri.com'
REPORT_URI = "https://#{REPORT_URI_SUBDOMAIN}/r/d/csp/reportOnly".freeze # Turn on wizard mode

BASE_CSP = {
  'default-src' => ["'self'"],
  'font-src' => ["'self'", 'https://fonts.gstatic.com'],
  'img-src' => ["'self'", 'https:'],
  'frame-src' => ['https://utteranc.es'],
  'report-uri' => [REPORT_URI],
  'script-src' => [],
  'style-src' => []
}.freeze

def get_scripts(path)
  html = File.open(path, 'r') { |f| Nokogiri::HTML(f) }
  sources = Set.new(html.xpath('//script').map do |script|
    if script['src']
      uri = URI.parse(script['src'])
      "#{uri.scheme}://#{uri.host}"
    end
  end.compact)
  shas = Set.new(html.xpath('//script[not(@src)]')
                 .reject { |script| script.text.empty? }
                 .map { |script| "sha256-#{Digest::SHA256.base64digest(script.text)}" })
  sources.merge(shas).to_a
end

def get_styles(path)
  html = File.open(path, 'r') { |f| Nokogiri::HTML(f) }
  sources = Set.new(html.xpath('//link[@rel="stylesheet"]/@href').map { |s| URI.parse(s).to_s })
  shas = Set.new(html.xpath('//style').reject do |style|
                   style.text.empty?
                 end.map { |style| "sha256-#{Digest::SHA256.base64digest(style.text)}" })
  sources.merge(shas).to_a
end

def file_csp(file)
  scripts = get_scripts(file)
  styles = get_styles(file)
  {
    'script-src' => scripts,
    'style-src' => styles
  }
end

def gen_csp_headers(policies)
  lines = ['/*',
           '  X-Frame-Options: DENY',
           '  X-XSS-Protection: 1; mode=block',
           '  Referrer-Policy: no-referrer-when-downgrade',
           "  Report-To: {\"group\":\"default\",\"max_age\":31536000,\"endpoints\":[{\"url\":\"https://#{REPORT_URI_SUBDOMAIN}/a/d/g\"}],\"include_subdomains\":true}",
           '  NEL: {"report_to":"default","max_age":31536000,"include_subdomains":true}']
  policy = policies.map { |key, p| "#{key} #{p.join(' ')}" }
  lines.push("  Content-Security-Policy-Report-Only: #{policy.join('; ')}")
  lines
end

DESTINATION = ARGV[0]
HTML_FILES = Dir["#{DESTINATION}/**/*.html"]

policies = BASE_CSP.dup
HTML_FILES.each do |path|
  sources = file_csp(path)
  sources.each do |key, source|
    policies[key].concat source
    policies[key] = policies[key].uniq
  end
end

File.open("#{DESTINATION}/_headers", 'w') do |outfile|
  outfile.puts(gen_csp_headers(policies))
end
