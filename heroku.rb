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
puts "What is the name of the bot/app: "
$appName = gets.chomp

puts ""
puts "Deploying #$appName..."
puts ""

puts "Checking git status"
if !File.directory?(".git")
    puts "ERROR: No git repository found."
    abort
elsif !execute("git status --porcelain")[:output].empty?
    puts "ERROR: Uncommited changes."
    abort
end
puts "OK"
puts ""

puts "Checking git branch"
if execute("git branch")[:output].include? "* master"
    puts "OK"
    puts ""
else
    puts "ERROR: You must be on the 'master' branch."
    abort
end

puts "Checking Heroku toolbelt"
if execute("which heroku")[:output].empty?
    puts "ERROR: Heroku toolbelt must be installed, visit: https://toolbelt.heroku.com"
    abort
end
puts "OK"
puts ""

puts "Checking Heroku status"
if execute("git remote show heroku")[:success]
    puts "ERROR: Heroku has already been configured."
    abort
end
puts "OK"
puts ""

puts "Creating Heroku app"
$check = execute("heroku apps:info " + $appName)
if $check[:output].include? "credentials"
    puts "ERROR: Please authentication with heroku toolbelt, run 'heroku login' then run this script again"
    abort
end

if !$check[:error].include? "Couldn't find that app"
    puts "ERROR: An app with that name already exists on heroku, please try again with a new name"
    abort
end

$creation = execute("heroku apps:create " + $appName + " --buildpack https://github.com/ChameleonBot/heroku-buildpack.git")
if $creation[:output].include? "credentials"
    puts "ERROR: Please authentication with heroku toolbelt, run 'heroku login' then run this script again"
    abort
elsif !$creation[:success]
    puts "ERROR: Unable to create Heroku app."
    abort
end
puts "OK"
puts ""

puts "Creating Procfile"
open('./Procfile', 'w') { |f|
    f.truncate(0)
    f.puts "web: " + $appName + " --env=production --port=$PORT"
}
puts "OK"
puts ""

if !execute("git status --porcelain")[:output].empty?
    puts "Commiting Procfile"
    if execute("git add . && git commit -m 'Add Procfile'")[:success]
        puts "OK"
        puts ""
        else
        puts "ERROR: Unable to commit Procfile."
        abort
    end
end

puts "Pushing to Heroku and building"
puts "Please wait, this may take a few minutes..."
$pushAndBuild = execute("heroku git:remote -a " + $appName + " && git push heroku master")
if !$pushAndBuild[:success]
    execute("heroku apps:destroy " + $appName + " --confirm " + $appName)

    puts "ERROR: Unable to push to Heroku."
    if $pushAndBuild[:error].include? "failed to compile"
        puts "The app failed to compile"
    end
    abort
end
puts "OK"
puts ""

puts "Starting the bot"
if !execute("heroku ps:scale web=1")[:success]
    puts "ERROR: Unable to start the bot."
    abort
end

$url = $creation[:output]
puts "Application started: " + $url
puts ""
puts "Done."

