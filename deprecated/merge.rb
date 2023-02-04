#!/usr/bin/env ruby
# frozen_string_literal: true

base = File.readlines(ARGV[0])
override = File.readlines(ARGV[1])

result = base.reject { |line| override.include?("-#{line}") }
result += override.reject { |line| line.start_with?('-') }
File.write(ARGV[0], result.join)
