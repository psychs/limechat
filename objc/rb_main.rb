require 'osx/cocoa'
include OSX
require_framework 'WebKit'
$KCODE = 'u'

require File.expand_path('../SACrashReporter/SACrashReporter.rb', __FILE__)

def _(s)
  NSLocalizedString(s)
end

def rb_main_init
  path = NSBundle.mainBundle.resourcePath.fileSystemRepresentation
  rbfiles = Dir.entries(path).select {|i| /\.rb\z/ =~ i}
  rbfiles -= [ File.basename(__FILE__) ]
  rbfiles -= [ 'utility.rb' ]
  require 'utility'
  rbfiles.each {|file| require File.basename(file)}
end

#if $0 == __FILE__ then
#  rb_main_init
#  OSX.NSApplicationMain(0, nil)
#end

NSApplication.sharedApplication
SACrashReporter.run_app
