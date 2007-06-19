# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class Preferences
  include OSX
  
  def initialize
    seed = {
      :units => []
    }
    #save_world(seed)
    #sync
  end
  
  def load_world
    read('world')
  end
  
  def save_world(c)
    write('world', c)
  end
  
  def load_window(key)
    read(key)
  end
  
  def save_window(key, value)
    write(key, value)
  end
  
  def sync
    NSUserDefaults.standardUserDefaults.synchronize
  end
  
  
  private

  def read(key)
    convert(NSUserDefaults.standardUserDefaults.objectForKey(key))
  end
  
  def write(key, value)
    NSUserDefaults.standardUserDefaults.setObject_forKey(value, key)
  end
  
  def convert(v)
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
    d.each {|k,v| r[k.to_s.to_sym] = convert(v) }
    r
  end
  
  def nsarray_to_array(a)
    r = []
    a.each {|i| r << convert(i) }
    r
  end
end
