# Created by Josh Goebel.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'dialoghelper'
require 'utility'

class CocoaSheet < OSX::NSObject
  include OSX
  include DialogHelper
  attr_accessor :window, :delegate, :prefix
  attr_reader :modal
  @@simple_buttons = []
  
  def initialize
    c = self.class.to_s
    @prefix = c.downcase_first
  end
  
  def start(*args)
    c = self.class.to_s
    NSBundle.loadNibNamed_owner(c, self)
    @sheet.makeFirstResponder(instance_variable_get("@#{@@first_responder}")) if @first_responder
    @model = true
    startup(*args) if respond_to?(:startup)
    NSApp.beginSheet_modalForWindow_modalDelegate_didEndSelector_contextInfo(@sheet, @window, self, 'sheetDidEnd:returnCode:contextInfo:', nil)
  end
  
  def self.first_responder(name)
    @first_responder = name
  end
  
  def self.buttons(*buttons)
    @@simple_buttons = buttons
    setup_buttons(buttons)
  end
  
  def self.setup_buttons(buttons)
    buttons.each_with_index do |button_name, index|
      button_name.gsub!(" ","")
      src = <<-end_src
        def on#{button_name}
          NSApp.endSheet_returnCode(@sheet, #{index})
        end
      end_src
      class_eval src, __FILE__, __LINE__
    end
  end
  
  def sheetDidEnd_returnCode_contextInfo(sender, code, info)
    @sheet.orderOut(self)
    @modal = false
    shutdown(@@simple_buttons[code].underscorize.to_sym)
  end
  
end
