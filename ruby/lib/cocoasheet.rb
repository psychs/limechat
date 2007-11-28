# Created by Josh Goebel.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'dialoghelper'
require 'utility'

class CocoaSheet < OSX::NSObject
  include OSX
  include DialogHelper
  attr_accessor :window, :delegate, :prefix
  ib_outlet :sheet
  attr_reader :modal
  
  class << self
    attr_reader :_first_responder, :_buttons
    
    def first_responder(value)
      @_first_responder = value
    end

    def buttons(*buttons)
      @_buttons = buttons
      @_buttons.each_with_index do |name, index|
        name = name.to_s
        name.gsub!(" ","")
        src = <<-end_src
          def on#{name}
            NSApp.endSheet_returnCode(@sheet, #{index})
          end
        end_src
        class_eval src, __FILE__, __LINE__
      end
    end
  end
  
  def initialize
    c = self.class.to_s
    @prefix = c.downcase_first
  end
  
  def start(*args)
    c = self.class.to_s
    NSBundle.loadNibNamed_owner(c, self)
    @sheet.makeFirstResponder(instance_variable_get("@#{self.class._first_responder}")) if self.class._first_responder
    @model = true
    startup(*args) if respond_to?(:startup)
    NSApp.beginSheet_modalForWindow_modalDelegate_didEndSelector_contextInfo(@sheet, @window, self, 'sheetDidEnd:returnCode:contextInfo:', nil)
  end
  
  def sheetDidEnd_returnCode_contextInfo(sender, code, info)
    @modal = false
    shutdown(self.class._buttons[code].to_s.underscorize.to_sym)
    @sheet.close
  end
  
end
