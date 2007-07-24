# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

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
    case v
    when OSX::NSAttributedString
      v.string.to_s
    when OSX::NSCFString,OSX::NSString
      v.to_s
    when OSX::NSCFBoolean
      v.boolValue
    when OSX::NSCFNumber,OSX::NSNumber
      OSX::CFNumberIsFloatType(v) ? v.to_f : v.to_i
    when OSX::NSDate
      v.to_time
    when OSX::NSCFDictionary,OSX::NSDictionary
      h = {}
      v.each {|k,i| h[k.to_s.to_sym] = convert_to_ruby_obj(i) }
      h
    when OSX::NSCFArray,OSX::NSArray
      v.map {|i| convert_to_ruby_obj(i)}
    else
      v
    end
  end
end
