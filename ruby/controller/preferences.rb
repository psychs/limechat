# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the same terms as Ruby.

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
    load('world')
  end
  
  def save_world(c)
    save('world', c)
  end
  
  def load(key)
    convert(NSUserDefaults.standardUserDefaults.objectForKey(key))
  end
  
  def save(key, value)
    NSUserDefaults.standardUserDefaults.setObject_forKey(value, key)
  end
  
  def sync
    NSUserDefaults.standardUserDefaults.synchronize
  end
  
  
  private
  
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
