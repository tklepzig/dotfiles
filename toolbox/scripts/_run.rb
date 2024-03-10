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

scripts = Dir.glob("#{SCRIPTS_PATH}/*").filter_map do |file|
  name = File.basename(file)
  next if ['_info.yaml', 'info.additional.yaml', '_run.rb'].include?(name)

  name
end

if ARGV[0] == '--details'
  puts "help:\e[0;32;2mShow help for given command\e[0m"
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

if ARGV[0] == '--list'
  puts 'help'
  puts scripts
  exit 0
end

if ARGV[0] == '--completion'
  puts scripts if ARGV[1] == 'help'
  script = ARGV[1]
  puts infos[script]['completion'] if infos[script].respond_to?(:key?) && infos[script].key?('completion')
  exit 0
end

if ARGV[0] == 'help'
  script_name = ARGV[1]

  unless scripts.include?(script_name)
    puts "Unknown script #{script_name}"
    exit 1
  end

  args_help = ''
  if infos[script_name].respond_to?(:key?) && infos[script_name].key?('args')
    args = infos[script_name]['args']
    args_help = args.map do |arg|
      default = arg['default'] ? " = #{arg['default']}" : ''
      arg['optional'] ? "[#{arg['name']}#{default}]" : arg['name']
    end.join(' ')
  end
  puts "Usage: #{script_name} #{args_help}"

  if infos[script_name].respond_to?(:key?) && infos[script_name].key?('help')
    help = infos[script_name]['help']
    puts ''
    puts help
  end

  exit 1
end

script_name = ARGV[0]

unless scripts.include?(script_name)
  puts "Unknown script #{script_name}"
  exit 1
end

if infos[script_name].respond_to?(:key?) && infos[script_name].key?('args')
  args = infos[script_name]['args']
  cmd_args = ARGV[1..]

  mandatory_args = args.filter { |arg| !arg['optional'] }
  if cmd_args.length < mandatory_args.length
    puts 'Error: Missing args:'
    puts mandatory_args.map { |arg| arg['name'] }[cmd_args.length..]
    exit 1
  end

  if cmd_args.length > args.length
    puts 'Error: Too many args'
    exit 1
  end
end

puts script_name
