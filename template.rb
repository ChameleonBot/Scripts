#!/usr/bin/ruby -w

require 'open3'

def execute(command)
    stdout, stderr, status = Open3.capture3(command)

    return {
        :output => stdout.to_s,
        :success => status.success?,
        :error => stderr.to_s,
    }
end


puts ""
puts "CHAMELEON"
puts ""
puts "What is the name of the new bot/app: "
$appName = gets.chomp

puts ""
puts "Creating #$appName..."
puts ""

puts "Cloning template repository"
if !execute("git clone https://github.com/ChameleonBot/Template.git " + $appName)[:success]
    puts "ERROR: Unable to clone repository."
    abort
end
Dir.chdir $appName
puts "OK"
puts ""

puts "Configuring development environment, this may take a few minutes"
if !execute("swift package generate-xcodeproj")[:success]
    puts "ERROR: Unable to create environment."
    abort
end
puts "OK"
puts ""
puts "Application created, open the xcode project file to begin"
puts ""
puts "Done."
