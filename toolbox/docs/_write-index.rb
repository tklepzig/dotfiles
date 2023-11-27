#!/usr/bin/env ruby
# frozen_string_literal: true

INDEX_PATH = File.join(__dir__, 'index.md')

def create_section(path, name)
  entries = Dir.glob(File.join(path, '*.md')).filter_map do |file|
    entry = File.basename(file)
    entry
  end
  { name:, entries: }
end

def write_index(sections)
  sections.each do |section|
    File.write(INDEX_PATH, "- [#{section[:name]}](##{section[:name].downcase})\n", mode: 'a')
  end
end

def write_sections(sections)
  sections.each do |section|
    File.write(INDEX_PATH, "\n# #{section[:name]}\n\n", mode: 'a')
    section[:entries].each do |entry|
      link = section[:name] == 'Toolbox' ? entry : File.join(section[:name], entry)
      File.write(INDEX_PATH, "- [#{File.basename(entry, '.*')}](#{link})\n", mode: 'a')
    end
  end
end

def init
  File.delete(INDEX_PATH) if File.exist?(INDEX_PATH)

  toolbox = create_section(__dir__, 'Toolbox')
  sub_dirs = Dir.glob(File.join(__dir__, '*/')).filter_map do |dir|
    name = File.basename(dir)
    next if name.start_with?('_')

    create_section(dir, name)
  end

  File.new(INDEX_PATH, 'w')
  [toolbox, *sub_dirs]
end

sections = init
write_index sections
write_sections sections
