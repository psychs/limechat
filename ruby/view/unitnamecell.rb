# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class UnitNameCell < OSX::NSTextFieldCell
  include OSX
  attr_accessor :view

  objc_method :drawInteriorWithFrame_inView, 'v@:{_NSRect={_NSPoint=ff}{_NSSize=ff}}@'
  def drawInteriorWithFrame_inView(frame, view)
    color = NSColor.colorWithCalibratedRed_green_blue_alpha(0.5,0.5,0.5,1.0)
    dic = {}
    dic[NSForegroundColorAttributeName] = color
    #dic[NSFontAttributeName] = NSFont.fontWithName_size("HiraKakuPro-W3", 18.0)
    str = self.stringValue
    str.drawInRect_withAttributes(frame, dic)
  end
end
