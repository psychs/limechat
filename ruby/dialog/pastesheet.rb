# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'cocoasheet'

class PasteSheet < CocoaSheet
  attr_accessor :uid, :cid
  ib_outlet :text, :sendButton, :syntaxPopup
  first_responder :sendButton
  buttons :Send, :Cancel
  
  def startup(str, mode, syntax, size)
    @sheet.setFrame_display(NSRect.new(NSPoint.new(0,0), size), false) if size
    @syntaxPopup.selectItemWithTag(syntax_to_tag(syntax))
    if mode == :edit
      @sheet.makeFirstResponder(@text)
    end
    @text.textStorage.setAttributedString(NSAttributedString.alloc.initWithString(str))
  end
  
  def shutdown(result)
    syntax = tag_to_syntax(@syntaxPopup.selectedItem.tag)
    if result == :send
      fire_event('onSend', @text.textStorage.string.to_s, syntax, @sheet.frame.size)
    else
      fire_event('onCancel', syntax, @sheet.frame.size)
    end
  end
  
  private
  
  SYNTAXES = [
    'privmsg', 'notice', 'c++', 'css', 'diff',
    'html_rails', 'html', 'java', 'javascript', 'php',
    'plain_text', 'python', 'ruby', 'ruby_on_rails', 'sql',
    'shell-unix-generic',
  ]
  
  def syntax_to_tag(syntax)
    SYNTAXES.index(syntax)
  end
  
  def tag_to_syntax(tag)
    SYNTAXES[tag]
  end
end
