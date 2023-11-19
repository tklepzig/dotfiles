#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'

HOME ||= ENV['HOME']
SCRIPTS_PATH ||= "#{HOME}/.dotfiles/toolbox/scripts".freeze

infos = YAML.load_file("#{SCRIPTS_PATH}/_info.yaml")

if File.exist?("#{SCRIPTS_PATH}/info.additional.yaml")
  infos_additional = YAML.load_file("#{SCRIPTS_PATH}/info.additional.yaml")
  infos.merge!(infos_additional) if infos_additional
end

if File.exist?("#{SCRIPTS_PATH}/info.local.yaml")
  infos_local = YAML.load_file("#{SCRIPTS_PATH}/info.local.yaml")
  infos.merge!(infos_local) if infos_local
end

scripts = Dir.glob("#{SCRIPTS_PATH}/*").filter_map do |file|
  name = File.basename(file)
  next if ['_info.yaml', '_info.additional.yaml', '_run.rb'].include?(name)

  name
end

if ARGV[0] == '--list'
  scripts.each do |script|
    description = if infos[script].respond_to?(:key?) && infos[script].key?('help')
                    ":\e[0;32;2m#{infos[script]['help'].split("\n")[0]}\e[0m"
                  else
                    ":\e[0;15;2mNo help for #{script}\e[0m"
                  end
    puts "#{script}#{description}"
  end
  exit 0
end

if ARGV[0] == '--list-short'
  puts scripts
  exit 0
end

if ARGV[0] == '--completion'
  script = ARGV[1]
  if infos[script].respond_to?(:key?) && infos[script].key?('completion')
    puts infos[script]['completion']
  end
  exit 0
end

script_name = ARGV[0]

unless scripts.include?(script_name)
  puts "Unknown script #{script_name}"
  exit 1
end

if ARGV[1] == '-h'
  puts(infos[script_name].respond_to?(:key?) && infos[script_name].key?('help') ? infos[script_name]['help'] : "No help for #{script_name}")
  exit 1
end

if infos[script_name].respond_to?(:key?) && infos[script_name].key?('params')
  params = infos[script_name]['params']
  args = ARGV[1..]

  if params.length != args.length
    puts 'Missing params:'
    puts params[args.length..]
    exit 1
  end
end

if ARGV[ARGV.length - 1] == '-n'
  File.readlines("#{SCRIPTS_PATH}/#{script_name}").drop(1).each do |line|
    puts line unless line.strip.empty?
  end
  exit 1
end

puts script_name
