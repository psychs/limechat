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
    when 'OSX::NSCFString'; v.to_s
    when 'OSX::NSCFBoolean'; v.to_i != 0
    when 'OSX::NSCFDictionary'; nsdictionary_to_hash(v)
    when 'OSX::NSCFArray'; nsarray_to_array(v)
    when 'OSX::NSCFNumber'
      if v.isEqualToNumber(OSX::NSNumber.numberWithInt(v.to_i))
        v.to_i
      else
        v.to_f
      end
    else
      v
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
