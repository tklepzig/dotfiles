#!/usr/bin/env ruby
# frozen_string_literal: true

def find_override(file_path)
  return "#{file_path}.override" if File.exist?("#{file_path}.override")

  override_before_extension = file_path.gsub(/(.*)(\..+)$/, '\1.override\2')
  return override_before_extension if File.exist?(override_before_extension)
end

file_path = ARGV[0]
print find_override(file_path)
