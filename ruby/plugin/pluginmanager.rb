# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class PluginManager
  
  class PluginInfo
    attr_reader :filename, :constant, :klass, :instances, :filesize, :filetime
    
    def initialize(filename, constant, klass)
      @filename = filename
      @constant = constant
      @klass = klass
      @instances = []
      @filesize = File.size?(@filename)
      @filetime = File.mtime(@filename) rescue nil
    end
    
    def add_instance(i)
      @instances << i
    end
    
    def remove_instance(i)
      @instances.delete(i)
    end
  end
  
  
  Suffix = '.rb'
  
  def initialize(owner, dir)
    @owner = owner
    @dir = File.expand_path(dir)
    @info = {}
    @serial = 0
  end
  
  def load_all
    find_all.each {|i| load(i)}
  end
  
  def unload_all
    @m.keys.each {|i| unload(base)}
  end
  
  
  private
  
  def find_all
    range = @dir.length+1...-Suffix.length
    Dir.glob("#{@dir}/**/*#{Suffix}").select {|i| File.file?(i)}.map{|i| i[range]}
  end
  
  def loaded?(base)
    @info.has_key?(base)
  end
  
  def load(base)
    fname = "#{@dir}/#{base}#{Suffix}"
    return false unless File.file?(fname)
    
    unload(base)
    
    name = "Plugin_" + base.gsub(/[^a-zA-Z\d]/, '_')
    constant = "#{name}_#{serial}"
    klass = PluginManager.const_set(constant, Class.new(Plugin))
    klass.class_eval(File.read(fname), fname)
    klass.on_load
    
    m = PluginInfo.new(fname, constant, klass)
    @info[base] = m
  rescue
    p $!
  end
  
  def unload(base)
    return unless loaded?(base)
    m = @info[base]
    klass = m.klass
    klass.on_unload
    PluginManager.send(:remove_const, m.constant)
    @info.delete(m)
  rescue
    p $!
  end
  
  def serial
    @serial += 1
  end
end
