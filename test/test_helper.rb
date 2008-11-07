$KCODE = 'u'

APP_ROOT = File.expand_path('../../', __FILE__)

require 'osx/cocoa'
include OSX
require_framework 'WebKit'

require 'rubygems' rescue LoadError
require 'test/spec'
require 'mocha'
require 'rucola/test_case'

$: << File.join(APP_ROOT, 'vendor', 'rubycocoa-prefs', 'lib')

Dir.glob("#{APP_ROOT}/ruby/*").each do |dir|
  $: << dir if File.directory?(dir)
end

Dir.glob("#{APP_ROOT}/ruby/**/*.rb").each do |file|
  require File.basename(file)
end