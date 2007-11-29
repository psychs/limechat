# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'cocoasheet'

class PasteSheet < CocoaSheet
  attr_accessor :uid, :cid
  ib_outlet :text, :sendButton, :syntaxPopup, :progressIndicator, :errorLabel
  first_responder :sendButton
  buttons :Cancel
  
  def startup(str, mode, syntax, size)
    @sheet.setContentSize(size) if size
    @syntaxPopup.selectItemWithTag(syntax_to_tag(syntax))
    if mode == :edit
      @sheet.makeFirstResponder(@text)
    end
    @text.textStorage.setAttributedString(NSAttributedString.alloc.initWithString(str))
  end
  
  def shutdown(button)
    syntax = tag_to_syntax(@syntaxPopup.selectedItem.tag)
    if @result
      fire_event('onSend', @result, syntax, @sheet.frame.size)
    else
      @conn.cancel if @conn
      fire_event('onCancel', syntax, @sheet.contentView.frame.size)
    end
  end
  
  def close
    NSApp.endSheet_returnCode(@sheet, 0)
  end
  
  def onSend(sender)
    syntax = tag_to_syntax(@syntaxPopup.selectedItem.tag)
    case syntax
    when 'privmsg','notice'
      @result = @text.textStorage.string.to_s
      close
    else
      @interval = 10
      set_requesting
      syntax = tag_to_syntax(@syntaxPopup.selectedItem.tag)
      @result = nil
      @conn = PastieClient.alloc.init
      @conn.delegate = self
      @conn.start(@text.textStorage.string.to_s, syntax)
    end
  end
  
  def pastie_on_success(sender, s)
    @conn = nil
    if s.empty?
      @errorLabel.setStringValue("Could not get an URL from Pastie")
      set_waiting
    else
      @errorLabel.setStringValue('')
      @result = s
      close
    end
  end
  
  def pastie_on_error(sender, e)
    @conn = nil
    @errorLabel.setStringValue("Pastie failed: #{e}")
    set_waiting
  end
  
  def on_timer
    if @conn
      @interval -= 1
      if @interval <= 0
        @conn.cancel
        @conn = nil
        @errorLabel.setStringValue("Unable to reach Pastie at this moment")
        set_waiting
      end
    end
  end
  
  
  private
  
  def set_requesting
    @errorLabel.setStringValue("Sending...")
    @progressIndicator.startAnimation(nil)
    @sendButton.setEnabled(false)
    @syntaxPopup.setEnabled(false)
  end
  
  def set_waiting
    @progressIndicator.stopAnimation(nil)
    @sendButton.setEnabled(true)
    @syntaxPopup.setEnabled(true)
  end
  
  SYNTAXES = [
    'privmsg', 'notice', 'c++', 'css', 'diff',
    'html_rails', 'html', 'java', 'javascript', 'php',
    'plain_text', 'python', 'ruby', 'ruby_on_rails', 'sql',
    'shell-unix-generic', 'perl', 'haskell', 'scheme',
  ]
  
  def syntax_to_tag(syntax)
    SYNTAXES.index(syntax)
  end
  
  def tag_to_syntax(tag)
    SYNTAXES[tag]
  end
end
