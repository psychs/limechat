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
    case v.class.to_s
      when 'OSX::NSCFString'; return v.to_s
      when 'OSX::NSCFNumber'; return v.to_i   # ignores float
      when 'OSX::NSCFBoolean'; return v.to_i != 0
      when 'OSX::NSCFDictionary'; return nsdictionary_to_hash(v)
      when 'OSX::NSCFArray'; return nsarray_to_array(v)
      else return v
    end
  end

  def nsdictionary_to_hash(d)
    r = {}
    d.each {|k,v| r[k.to_s.to_sym] = convert_to_ruby_obj(v) }
    r
  end

  def nsarray_to_array(a)
    r = []
    a.each {|i| r << convert_to_ruby_obj(i) }
    r
  end
end
