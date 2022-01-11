#!/usr/bin/env ruby
require 'erb'

baseurl = ENV["BASEURL"]
raise 'BASEURL env var not found' if baseurl.nil?

file_data = File.read(ARGV[0])

template = ERB.new(file_data)

File.write(ARGV[1], template.result)
