# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

module DialogHelper
  include OSX
  
  module DialogHelperClassMethods
    attr_reader :mapped_outlets

    def ib_mapped_outlet(*args)
      add_mapped_outlet(args, nil)
    end

    def ib_mapped_int_outlet(*args)
      add_mapped_outlet(args, :int)
    end

    def ib_mapped_radio_outlet(*args)
      add_mapped_outlet(args, :radio)
    end
    
    private
    
    def add_mapped_outlet(args, type)
      @mapped_outlets ||= []
      args.each do |i|
        @mapped_outlets << { :name => i, :type => type }
      end
      ib_outlet(*args)
    end
  end
  
  def self.included(receiver)
    receiver.extend(DialogHelperClassMethods)
  end
  
  def load_mapped_outlets(model, nest=false)
    return unless mapped_outlets
    mapped_outlets.each {|i| load_outlet_value(i, model, nest) }
  end
  
  def save_mapped_outlets(model, nest=false)
    return unless mapped_outlets
    mapped_outlets.each {|i| save_outlet_value(i, model, nest) }
  end
  
  
  private
  
  def set_table_header_settings(table, ary)
    table.tableColumns.to_a.each_with_index do |i,n|
      w = ary[n]
      i.setWidth(w) if w
    end
  end
  
  def get_table_header_settings(table)
    ary = []
    table.tableColumns.to_a.each {|i| ary << i.width}
    ary
  end
  
  def fire_event(name, *args)
    method = @prefix + '_' + name
    if @delegate && @delegate.respond_to?(method)
      @delegate.__send__(method, self, *args)
    end
  end
  
  def mapped_outlets
    self.class.mapped_outlets
  end
  
  def outlet_to_slot(s)
    if /^([a-zA-Z\d_]+)[A-Z][a-z]+$/ =~ s
      $1
    else
      s
    end
  end
  
  def outlet_to_nested_slot(s)
    if /^([a-zA-Z\d]+)_([a-zA-Z\d_]+)$/ =~ s
      [$1, $2]
    else
      nil
    end
  end
  
  def load_outlet_value(outlet, model, nest)
    name = outlet[:name].to_s
    type = outlet[:type]
    
    if nest
      category, slot = outlet_to_nested_slot(name)
      raise ArgumentError unless category && slot
      obj = model.__send__(category)
      v = obj.__send__(slot)
    else
      v = model.__send__(outlet_to_slot(name))
    end
    
    t = instance_variable_get('@' + name)
    case t
    when NSMatrix
      case type
      when :radio
        t.selectCellWithTag(v)
      end
    when NSComboBox,NSTextField
      t.setStringValue(v)
    when NSTextView
      t.textStorage.setAttributedString(NSAttributedString.alloc.initWithString(v.join("\n")))
    when NSPopUpButton
      case type
      when :int
        t.selectItemWithTag(v)
      else
        t.selectItemWithTitle(v)
      end
    when NSButton
      t.setState(v ? 1 : 0)
    end
  end
  
  def save_outlet_value(outlet, model, nest)
    name = outlet[:name].to_s
    type = outlet[:type]
    
    if nest
      category, slot = outlet_to_nested_slot(name)
      raise ArgumentError unless category && slot
      model = model.__send__(category)
      method = slot + '='
    else
      method = outlet_to_slot(name) + '='
    end
    
    t = instance_variable_get('@' + name)
    case t
    when NSMatrix
      case type
      when :radio
        v = t.selectedCell.tag
      else
        raise 'Outlet type is not supported'
      end
    when NSComboBox,NSTextField
      v = t.stringValue.to_s
      v = v.gsub(/\r\n|\r|\n/, ' ')
      v = v.to_i if type == :int
    when NSTextView
      v = t.textStorage.string.to_s
      v = v.split(/\r\n|\r|\n/)
    when NSPopUpButton
      case type
      when :int
        v = t.selectedItem.tag
      else
        v = t.selectedItem.title
      end
    when NSButton
      v = t.state.to_i != 0
    else
      raise 'Outlet type is not supported'
    end
    model.__send__(method, v)
  end
end
