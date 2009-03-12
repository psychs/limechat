# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'cocoasheet'

class PasteSheet < CocoaSheet
  attr_accessor :uid, :cid, :nick
  attr_reader :original_text
  ib_outlet :text, :pasteButton, :sendInChannelButton, :syntaxPopup, :commandPopup, :progressIndicator, :errorLabel
  first_responder :sendInChannelButton
  buttons :Cancel
  
  def startup(str, mode, syntax, cmd, size)
    str = str.gsub(/\r\n|\r|\n/, "\n")
    @original_text = str
    
    @button = nil
    @short_text = false
    @mode = mode
    if @mode == :edit
      numlines = str.count("\n") + (str[-1,1] == "\n" ? 0 : 1)
      @short_text = numlines <= 3
      syntax = 'privmsg' if @short_text
      @sheet.makeFirstResponder(@text)
    end
    
    @syntaxPopup.selectItemWithTag(syntax_to_tag(syntax))
    @commandPopup.selectItemWithTag(syntax_to_tag(cmd))
    @text.textStorage.setAttributedString(NSAttributedString.alloc.initWithString(str))
    @sheet.setContentSize(size) if size
    @sheet.key_delegate = self
  end
  
  def shutdown(button)
    syntax = tag_to_syntax(@syntaxPopup.selectedItem.tag)
    cmd = tag_to_syntax(@commandPopup.selectedItem.tag)
    if @result
      fire_event('onSend', @result, @button, syntax, cmd, @sheet.frame.size, @mode, @short_text)
    else
      @conn.cancel if @conn
      fire_event('onCancel', syntax, cmd, @sheet.contentView.frame.size, @mode, @short_text)
    end
  end
  
  def close
    NSApp.endSheet_returnCode(@sheet, 0)
  end
  
  def onSendInChannel(sender)
    @button = :send
    @result = @text.textStorage.string.to_s
    close
  end
  
  def onPasteOnline(sender)
    @button = :paste
    @interval = 10
    set_requesting
    syntax = tag_to_syntax(@syntaxPopup.selectedItem.tag)
    @result = nil
    @conn = PasternakClient.alloc.init
    #@conn = PastieClient.alloc.init
    @conn.delegate = self
    @conn.start(@text.textStorage.string.to_s, @nick, syntax)
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
    @pasteButton.setEnabled(false)
    @sendInChannelButton.setEnabled(false)
    @syntaxPopup.setEnabled(false)
    @commandPopup.setEnabled(false)
  end
  
  def set_waiting
    @progressIndicator.stopAnimation(nil)
    @pasteButton.setEnabled(true)
    @sendInChannelButton.setEnabled(true)
    @syntaxPopup.setEnabled(true)
    @commandPopup.setEnabled(true)
  end
  
  SYNTAXES = [
    'privmsg', 'notice', 'c++', 'css', 'diff',
    'html_rails', 'html', 'java', 'javascript', 'php',
    'plain_text', 'python', 'ruby', 'ruby_on_rails', 'sql',
    'shell-unix-generic', 'perl', 'haskell', 'scheme', 'objective-c',
  ]
  
  def syntax_to_tag(syntax)
    SYNTAXES.index(syntax)
  end
  
  def tag_to_syntax(tag)
    SYNTAXES[tag]
  end
end
