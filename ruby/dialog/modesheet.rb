# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'dialoghelper'
require 'utility'

class ModeSheet < OSX::NSObject
  include OSX
  include DialogHelper

  attr_accessor :window, :delegate, :prefix
  attr_accessor :mode, :uid, :cid
  attr_reader :modal
  ib_mapped_outlet :sCheck, :pCheck, :nCheck, :tCheck, :tCheck, :iCheck, :mCheck, :aCheck, :rCheck
  ib_outlet :sheet, :kCheck, :lCheck, :password, :limit
  
  def initialize
    @prefix = 'modeSheet'
  end
  
  def loadNib
    NSBundle.loadNibNamed_owner('ModeSheet', self)
  end
  
  def start(chname, mode)
    @mode = mode.dup
    @modal = true
    @sheet.makeFirstResponder(@sCheck)
    load
    update
    
    case chname.first_char
    when '!'
      @aCheck.setEnabled(true)
      @rCheck.setEnabled(true)
    when '&'
      @aCheck.setEnabled(true)
      @rCheck.setEnabled(false)
    else
      @aCheck.setEnabled(false)
      @rCheck.setEnabled(false)
    end
    
    NSApp.beginSheet_modalForWindow_modalDelegate_didEndSelector_contextInfo(@sheet, @window, self, 'sheetDidEnd:returnCode:contextInfo:', nil)
  end
  
  objc_method :sheetDidEnd_returnCode_contextInfo, 'v@:@i^v'
  def sheetDidEnd_returnCode_contextInfo(sender, code, info)
    @sheet.orderOut(self)
    @modal = false
    save
    if code != 0
      fire_event('onOk', @mode)
    else
      fire_event('onCancel')
    end
  end

  def load
    load_mapped_outlets(@mode)
    @kCheck.setState(!@mode.k.empty? ? 1 : 0)
    @lCheck.setState(@mode.l > 0 ? 1 : 0)
    @password.setStringValue(@mode.k)
    @limit.setIntValue(@mode.l)
  end
  
  def save
    save_mapped_outlets(@mode)
    if @kCheck.state == 1 && !@password.stringValue.to_s.empty?
      @mode.k = @password.stringValue.to_s
    else
      @mode.k = ''
    end
    if @lCheck.state == 1 && !@limit.stringValue.to_s.empty?
      @mode.l = @limit.stringValue.to_s.to_i
    else
      @mode.l = 0
    end
  end
  
  def update
    @password.setEnabled(@kCheck.state == 1)
    @limit.setEnabled(@lCheck.state == 1)
  end
  
  def onOk(sender)
    NSApp.endSheet_returnCode(@sheet, 1)
  end
  
  def onCancel(sender)
    NSApp.endSheet_returnCode(@sheet, 0)
  end
  
  def onChangeChecks(sender)
    if @sCheck.state == 1 && @pCheck.state == 1
      case sender.__ocid__
      when @sCheck.__ocid__; @pCheck.setState(0)
      when @pCheck.__ocid__; @sCheck.setState(0)
      end
    end
    update
  end
end
