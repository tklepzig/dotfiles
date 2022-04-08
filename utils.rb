class String
  def accent
    colorize "\e[1;34m"
  end

  def success
    colorize "\e[0;92m"
  end

  def error
    colorize "\e[0;91m"
  end

  private

  def colorize(color)
    "#{color}#{self}\e[0m"
  end
end

module Logger
  @level = 0

  def self.log(*message_parts, newline: true)
    message = message_parts.join
    message = message.rjust(message.length + 2 * @level)

    if newline
      puts message
    else
      print message
    end
  end

  def self.indent
    @level += 1
  end

  def self.outdent
    @level -= 1
    @level = 0 if @level.negative?
  end

  def self.reset_indentation
    @level = 0
  end
end

module OS
  def self.mac?
    (/darwin/ =~ RUBY_PLATFORM) != nil
  end

  def self.linux?
    (/linux/ =~ RUBY_PLATFORM) != nil
  end
end

def program_installed?(program)
  result = `sh -c 'command -v #{program}'`
  return true unless result.empty?

  false
end

def check_mandatory_installation(program)
  Logger.log 'Searching for ', program.accent, '...', newline: false

  if program_installed? program
    path = `which #{program}`
    Logger.log " Found: #{path.strip}.".success
    return true
  end

  Logger.log ' Not found, aborting'.error
  false
end

def check_optional_installation(program, install_name = program)
  Logger.log 'Searching for ', program.accent, '...', newline: false

  if program_installed? program
    Logger.log ' Found.'.success
    return
  end

  Logger.log " Not Found. (Try \"sudo pacman -S #{install_name}\")".error
end

def add_link_to_file(link, file, command = 'source')
  File.new(file, 'w') unless File.exist?(file)
  `grep -q #{link} #{file}`

  return if $CHILD_STATUS.success?

  Logger.log 'Adding link to ', file.accent, '...', newline: false
  File.open(file, 'a') do |f|
    f.puts "#{command} #{link}"
  end
  Logger.log ' Done.'.success
end
