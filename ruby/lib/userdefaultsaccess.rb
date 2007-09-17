# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'utility'

module UserDefaultsAccess
  
  private
  
  def read_defaults(key)
    convert_to_ruby_obj(OSX::NSUserDefaults.standardUserDefaults.objectForKey(key))
  end

  def write_defaults(key, value)
    OSX::NSUserDefaults.standardUserDefaults.setObject_forKey(value, key)
  end
  
  def convert_to_ruby_obj(v)
    return v if v == nil || v == false || v == true
    v.is_a?(OSX::NSObject) ? v.to_ruby : v
  end
end
