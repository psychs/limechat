require 'rubygems' rescue LoadError
require 'test/spec'

APP_ROOT = File.expand_path('../../', __FILE__)

require 'osx/cocoa'
include OSX

$:.unshift << File.join(APP_ROOT, 'ruby/lib')
$:.unshift << File.join(APP_ROOT, 'ruby')