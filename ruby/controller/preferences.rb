# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'userdefaultsaccess'
require 'persistencehelper'

class Preferences
  include OSX
  include UserDefaultsAccess
  
  class << self
    attr_reader :models
    def model_attr(*args)
      @models ||= []
      @models += args
      attr_reader(*args)
    end
  end
  
  class Keyword
    include PersistenceHelper
    persistent_attr :words
    def initialize
      @words = []
    end
  end
  
  class Dcc
    include PersistenceHelper
    persistent_attr :port_begin, :port_end, :addr_method
    def initialize
      @port_begin = 1096
      @port_end = 1115
      @addr_method = 'nic'
    end
  end
  
  model_attr :key, :dcc
  
  def initialize
    @key = Keyword.new
    @dcc = Dcc.new
  end
    
  def load
    self.class.models.each do |i|
      m = instance_variable_get('@' + i.to_s)
      d = read_defaults(i.to_s)
      m.set_persistent_attrs(d)
    end
  end
  
  def save
    self.class.models.each do |i|
      m = instance_variable_get('@' + i.to_s)
      h = m.get_persistent_attrs
      write_defaults(i.to_s, h)
    end
  end
  
  def load_world
    read_defaults('world')
  end
  
  def save_world(c)
    write_defaults('world', c)
  end
  
  def load_window(key)
    read_defaults(key)
  end
  
  def save_window(key, value)
    write_defaults(key, value)
  end
  
  def sync
    NSUserDefaults.standardUserDefaults.synchronize
  end
end
