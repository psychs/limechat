require 'osx/cocoa'
require File.expand_path('../SACrashReporter/SACrashReporter.rb', __FILE__)

def rb_main_init
  $KCODE = 'u'
  OSX.require_framework 'WebKit'
  
  path = OSX::NSBundle.mainBundle.resourcePath.fileSystemRepresentation
  rbfiles = Dir.entries(path).select {|x| /\.rb\z/ =~ x}
  rbfiles -= [ File.basename(__FILE__) ]
  rbfiles.each do |path|
    require( File.basename(path) )
  end
end

#if $0 == __FILE__ then
#  rb_main_init
#  OSX.NSApplicationMain(0, nil)
#end

SACrashReporter.run_app
