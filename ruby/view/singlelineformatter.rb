# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class SingleLineFormatter < OSX::NSFormatter
  include OSX
  
  addRubyMethod_withType 'stringForObjectValue:', '@@:@'
  def stringForObjectValue(str)
    str.to_s.gsub(/\r?\n/m, ' ')
  end
  
  addRubyMethod_withType 'getObjectValue:forString:errorDescription:', 'i@:^@@^@'
  def getObjectValue_forString_errorDescription(objp, str, err)
    s = str.to_s.gsub(/\r?\n/m, ' ')
    objp.assign(NSString.stringWithString(s))
    true
  end
  
  addRubyMethod_withType 'isPartialStringValid:newEditingString:errorDescription:', 'i@:@^@^@'
  def isPartialStringValid_newEditingString_errorDescription(str, strp, err)
    s = str.to_s
    return true unless s =~ /\r?\n/m
    s = s.gsub(/\r?\n/m, ' ')
    strp.assign(NSString.stringWithString(s))
    false
  end
end
