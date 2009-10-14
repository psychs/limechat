# Copyright (c) 2006-2008, The RubyCocoa Project.
# Copyright (c) 2001-2006, FUJIMOTO Hisakuni.
# All Rights Reserved.
#
# RubyCocoa is free software, covered under either the Ruby's license or the 
# LGPL. See the COPYRIGHT file for more information.

require 'osx/objc/oc_all.rb'
require 'osx/objc/cocoa_macros'

p = '/System/Library/BridgeSupport/libSystem.bridgesupport'
OSX.load_bridge_support_file(p) if File.exist?(p)

# FIXME: 10.6 Foundation.bridgesupport defines the value64 of NSNotFound as -1
module OSX
  remove_const(:NSNotFound)
  NSNotFound = NSIntegerMax
end
