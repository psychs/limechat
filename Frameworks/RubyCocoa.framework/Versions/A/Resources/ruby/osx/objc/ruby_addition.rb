# Copyright (c) 2006-2008, The RubyCocoa Project.
# Copyright (c) 2001-2006, FUJIMOTO Hisakuni.
# All Rights Reserved.
#
# RubyCocoa is free software, covered under either the Ruby's license or the 
# LGPL. See the COPYRIGHT file for more information.

# String additions.
class String
  
  def nsencoding
    warn "#{caller[0]}: nsencoding is now deprecated and its use is discouraged, please use 'NKF.guess(rbstr)' instead."
    OSX::NSString.guess_nsencoding(self)
  end
	
  def to_nsstring
    warn "#{caller[0]}: to_nsstring is now deprecated and its use is discouraged, please use to_ns instead."
    OSX::NSString.stringWithRubyString(self)
  end
  
  def to_nsmutablestring
    warn "#{caller[0]}: to_nsmutablestring is now deprecated and its use is discouraged, please use to_ns instead."
    OSX::NSMutableString.stringWithRubyString(self)
  end
  
  def to_sel
    s = self.dup
    s.instance_variable_set(:@__is_sel__, true)
    return s
  end

end

# Property list API.
module OSX
  def load_plist(data)
    nsdata = OSX::NSData.alloc.initWithBytes_length(data.to_s)
    obj, error = OSX::NSPropertyListSerialization.objc_send \
      :propertyListFromData, nsdata,
      :mutabilityOption, OSX::NSPropertyListImmutable,
      :format, nil,
      :errorDescription
    raise error.to_s if obj.nil?
    obj.respond_to?(:to_ruby) ? obj.to_ruby : obj
  end
  module_function :load_plist

  def object_to_plist(object, format=nil)
    format ||= OSX::NSPropertyListXMLFormat_v1_0
    data, error = OSX::NSPropertyListSerialization.objc_send \
      :dataFromPropertyList, object,
      :format, format,
      :errorDescription
    raise error.to_s if data.nil?
    case format
      when OSX::NSPropertyListXMLFormat_v1_0, 
           OSX::NSPropertyListOpenStepFormat
        OSX::NSString.alloc.initWithData_encoding(data, 
          OSX::NSUTF8StringEncoding).to_s
      else
        data.bytes.bytestr(data.length)
    end
  end
  module_function :object_to_plist
end

[Array, Hash, String, Numeric, TrueClass, FalseClass, Time].each do |k| 
  k.class_eval do
    def to_plist(format=nil)
      OSX.object_to_plist(self, format)
    end
    def to_ns
      OSX.rbobj_to_nsobj(self)
    end
  end
end

# Pascal strings API.
class Array
  def pack_as_pstring
    len = self[0]
    self[1..-1].pack("C#{len}")
  end
end

class String
  def unpack_as_pstring
    ary = [self.length]
    ary.concat(self.unpack('C*'))
    return ary
  end
end

class Thread
  class << self
    alias :pre_rubycocoa_new :new
    
    # Override Thread.new to prevent threads being created if there isn't 
    # runtime support for it
    def new(*args,&block)
      unless defined? @_rubycocoa_threads_allowed then
        # If user has explicilty disabled thread support, also disable the 
        # check (for debugging/testing only)
        @_rubycocoa_threads_allowed = ENV['RUBYCOCOA_THREAD_HOOK_DISABLE'] || 
          OSX::RBRuntime.isRubyThreadingSupported?
      end
      if !@_rubycocoa_threads_allowed then
        warn "#{caller[0]}: Ruby threads cannot be used in RubyCocoa without patches to the Ruby interpreter"
      end
      pre_rubycocoa_new(*args,&block)
    end
  end
end
