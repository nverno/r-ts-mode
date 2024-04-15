#!/usr/bin/env ruby
# frozen_string_literal: true

##
# Extract code sections from corpii
##

content = []
ARGF.each_line do |line| 
  content << line
end

sections = content.join.split(/==+\n.*\n==+/)
res = []
sections.each do |section| 
  s = section.split(/\n*---+\n+/).first
  next unless s

  res << s.strip
end

puts res.join("\n\n")
