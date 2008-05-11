require 'rubygems'
require 'net/ssh'

def main
  Dir.chdir('/Users/psychs/git/limechat/web')
  
  puts '* copying...'
  system('scp -r * psychs@shell.sourceforge.net:~/htdocs')
  puts '* copied'

  begin
    puts '* connecting'
    session = Net::SSH.start("shell.sourceforge.net", 22, "psychs");
    shell = session.shell.sync
    if shell.open? then
      puts '* connected'
      puts '* deploying...'
      shell.send_command("deploy.rb").stdout
      puts '* deployed'
      shell.exit
    end
  ensure
    session.close if session
  end
end

main
