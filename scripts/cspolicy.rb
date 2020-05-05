#!/usr/bin/env ruby
# frozen_string_literal: true

require "nokogiri"
require "digest"

REPORT_URI_SUBDOMAIN = "whitw.report-uri.com".freeze
REPORT_URI = "https://#{REPORT_URI_SUBDOMAIN}/r/d/csp/reportOnly".freeze # Turn on wizard mode

BASE_CSP = {
  "default-src" => ["'self'"],
  "font-src" => ["'self'", "https://fonts.gstatic.com"],
  "img-src" => ["'self'", "https:"],
  "frame-src" => ["https://utteranc.es"],
  "report-uri" => [REPORT_URI],
  "script-src" => [],
  "style-src" => [],
}.freeze

def get_scripts(path)
  sources = []
  shas = []
  html = File.open(path, "r") { |f| Nokogiri::HTML(f) }
  html.xpath("//script").each do |script|
    unless script["src"].nil?
      uri = URI.parse(script["src"])
      sources.push("#{uri.scheme}://#{uri.host}")
    end
    script.text.empty? || shas.push("sha256-#{Digest::SHA256.base64digest(script.text)}")
  end
  sources.uniq + shas.uniq
  # "#{sources.uniq.join(" ")} #{shas.uniq.map { |s| "'#{s}'" }.join(" ")}".rstrip
end

def get_styles(path)
  html = File.open(path, "r") { |f| Nokogiri::HTML(f) }
  sources = html.xpath('//link[@rel="stylesheet"]/@href').to_a.map { |s| "#{URI.parse(s).scheme}://#{URI.parse(s).host}" }
  shas = []
  html.xpath("//style").each do |style|
    style.text.empty? || shas.push("sha256-#{Digest::SHA256.base64digest(style.text)}")
  end
  sources.uniq
  # "'unsafe-inline' #{sources.uniq.join(" ")}".rstrip #  #{shas.uniq.map{|s| "'#{s}'"}.join(' ')}".rstrip
end

def file_csp(file)
  # csp = DEFAULT_PAGE_CSP.dup
  scripts = get_scripts(file)
  styles = get_styles(file)
  {
    "script-src" => scripts,
    "style-src" => styles,
  }
  # csp.push("style-src #{get_styles(file)}")
  # [
  #   {
  #     url: "/#{file.split("/").drop(2).join("/")}",
  #     csp: csp.join("; "),
  #   },
  #   {
  #     url: "/#{file.split("/").drop(2).join("/").split("/index.html")[0]}",
  #     csp: csp.join("; "),
  #   },
  # ]
end

def gen_csp_headers(policies)
  lines = ["/*",
           "  X-Frame-Options: DENY",
           "  X-XSS-Protection: 1; mode=block",
           "  Referrer-Policy: no-referrer-when-downgrade",
           "  Report-To: {\"group\":\"default\",\"max_age\":31536000,\"endpoints\":[{\"url\":\"https://#{REPORT_URI_SUBDOMAIN}/a/d/g\"}],\"include_subdomains\":true}",
           '  NEL: {"report_to":"default","max_age":31536000,"include_subdomains":true}']
  policy = []
  policies.each do |key, p|
    policy.push("#{key} #{p.join(" ")}")
    #   chunks.push(%(#{policy[:url]}
    # Content-Security-Policy-Report-Only: #{policy[:csp]}))
  end
  lines.push("  Content-Security-Policy-Report-Only: #{policy.join("; ")}")
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

File.open("#{DESTINATION}/_headers", "w") do |outfile|
  outfile.puts(gen_csp_headers(policies))
end
