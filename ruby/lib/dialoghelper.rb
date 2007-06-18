# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

module DialogHelper
  module ClassMethods
    attr_reader :mapped_outlets

    def ib_mapped_outlet(*args)
      @mapped_outlets ||= []
      @mapped_outlets += args
      ib_outlet(*args)
    end
  end
  
  def self.included(receiver)
    receiver.extend(ClassMethods)
  end
  
  def load_mapped_outlets(model)
    return unless mapped_outlets
    mapped_outlets.each {|i| load_outlet_value(i, model) }
  end
  
  def save_mapped_outlets(model)
    return unless mapped_outlets
    mapped_outlets.each {|i| save_outlet_value(i, model) }
  end
  
  
  private
  
  def fire_event(name, *args)
    method = @prefix + '_' + name
    if @delegate && @delegate.respond_to?(method)
      @delegate.__send__(method, self, *args)
    end
  end
  
  def mapped_outlets
    self.class.mapped_outlets
  end
  
  def outlet_to_slot(sym)
    s = sym.to_s
    if /^([a-zA-Z\d_]+)[A-Z][a-z]+$/ =~ s
      $1
    else
      s
    end
  end
  
  def load_outlet_value(outlet, model)
    t = instance_variable_get('@' + outlet.to_s)
    v = model.__send__(outlet_to_slot(outlet))
    case t.class.to_s
    when 'OSX::NSTextField','OSX::NSComboBox'
      t.setStringValue(v)
    when 'OSX::NSButton'
      t.setState(v ? 1 : 0)
    when 'OSX::NSPopUpButton'
      t.selectItemWithTag(v)
    end
  end
  
  def save_outlet_value(outlet, model)
    t = instance_variable_get('@' + outlet.to_s)
    method = outlet_to_slot(outlet) + '='
    case t.class.to_s
    when 'OSX::NSTextField','OSX::NSComboBox'
      model.__send__(method, t.stringValue.to_s)
    when 'OSX::NSButton'
      model.__send__(method, t.state.to_i != 0)
    when 'OSX::NSPopUpButton'
      model.__send__(method, t.selectedItem.tag)
    end
  end
end
