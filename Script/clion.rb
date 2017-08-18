#!/Users/alex/.rvm/rubies/ruby-2.4.1/bin/ruby

project_name =
    Dir.glob(".idea/*.iml")[0]&.match(/\.idea\/(.*)\.iml/)[1] ||
    Dir.pwd.match(/.*\/([^\/]+)/)[1]
project_name.gsub!('-', '_')

str = """cmake_minimum_required(VERSION 3.7)
project(#{project_name})

add_custom_target(#{project_name}
        COMMAND /usr/bin/swift build
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        SOURCES Sources
"""
Dir.glob(".build/checkouts/*/Sources").each do |s|
  str << "        #{s}\n"
end

str << "        )\n"

File.write("CMakeLists.txt", str)

if ARGV[0] == "-n" || `which clion`.length == 0
  exit
elsif ARGV[0] == "-y"
  `clion .`
else
  puts "Do you wish to open CLion now? (y/n)"
  if gets.chomp == 'y'
    `clion .`
  end
end
