# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class Splitter < NSSplitView
  attr_reader :fixedViewIndex, :position, :dividerThickness
  
  def initialize
    @position = 0
    @fixedViewIndex = 0
    @dividerThickness = 1
    @inverted = false
    @hidden = false
  end
  
  def awakeFromNib
    @dividerThickness = vertical? ? 1 : 5
    updatePosition
  end
  
  def setFixedViewIndex(index)
    @fixedViewIndex = index
    @fixedViewIndex = @fixedViewIndex ? 0 : 1 if inverted?
    updatePosition
  end
  
  def setPosition(pos)
    @position = pos
    adjustSubviews
  end
  
  def setDividerThickness(value)
    @dividerThickness = value
    adjustSubviews
  end
  
  def setInverted(value)
    return if @inverted == !!value
    @inverted = !!value
    v = self.subviews.objectAtIndex(0)
    w = self.subviews.objectAtIndex(1)
    v.removeFromSuperviewWithoutNeedingDisplay
    w.removeFromSuperviewWithoutNeedingDisplay
    self.addSubview(w)
    self.addSubview(v)
    @fixedViewIndex = @fixedViewIndex != 0 ? 0 : 1
    adjustSubviews
  end
  
  def inverted?
    @inverted
  end
  
  def setVertical(value)
    super_setVertical(value)
    adjustSubviews
  end
  
  def vertical?
    isVertical
  end
  
  def setHidden(value)
    return if @hidden == !!value
    @hidden = !!value
    adjustSubviews
  end
  
  def hidden?
    @hidden
  end
  
  def drawDividerInRect(rect)
    if hidden?
      ;
    elsif vertical?
      NSColor.colorWithCalibratedWhite_alpha(0.65, 1).set
      NSRectFill(rect);
    else
      NSColor.colorWithCalibratedWhite_alpha(0.65, 1).set
      sp = rect.origin.dup
      ep = sp.dup
      ep.x += rect.width
      NSBezierPath.strokeLineFromPoint_toPoint(sp, ep)
      sp = rect.origin.dup
      sp.y += rect.height
      ep = sp.dup
      ep.x += rect.width
      NSBezierPath.strokeLineFromPoint_toPoint(sp, ep)
    end
  end
  
  def mouseDown(e)
    super_mouseDown(e)
    updatePosition
  end
  
  def resizeSubviewsWithOldSize(oldSize)
    adjustSubviews
  end
  
  def adjustSubviews
    if self.subviews.count != 2
      super_adjustSubviews
      return
    end
    
    frame = self.frame
    
    w = @dividerThickness
    fixedView = self.subviews.objectAtIndex(@fixedViewIndex)
    flyingView = self.subviews.objectAtIndex(@fixedViewIndex == 0 ? 1 : 0)
    fixedFrame = fixedView.frame
    flyingFrame = flyingView.frame
    
    if hidden?
      if vertical?
        fixedFrame = NSRect.new(0,0,0,frame.height)
        flyingFrame.x = 0
        flyingFrame.y = 0
        flyingFrame.width = frame.width
        flyingFrame.height = frame.height
      else
        fixedFrame = NSRect.new(0,0,frame.width,0)
        flyingFrame.x = 0
        flyingFrame.y = 0
        flyingFrame.width = frame.width
        flyingFrame.height = frame.height
      end
    elsif vertical?
      flyingFrame.width = frame.width - w - @position
      flyingFrame.height = frame.height
      flyingFrame.x = @fixedViewIndex == 0 ? @position + w : 0.0
      flyingFrame.y = 0.0
      flyingFrame.width = 0.0 if flyingFrame.width < 0.0
      fixedFrame.width = @position
      fixedFrame.height = frame.height
      fixedFrame.width = @position
      fixedFrame.height = frame.height
      fixedFrame.x = @fixedViewIndex == 0 ? 0.0 : flyingFrame.width + w
      fixedFrame.y = 0.0
      fixedFrame.width = frame.width - w if fixedFrame.width > frame.width - w
    else
      flyingFrame.width = frame.width
      flyingFrame.height = frame.height - w - @position
      flyingFrame.x = 0.0;
      flyingFrame.y = @fixedViewIndex == 0 ? @position + w : 0.0;
      flyingFrame.height = 0.0 if flyingFrame.height < 0.0
      fixedFrame.width = frame.width;
      fixedFrame.height = @position;
      fixedFrame.x = 0.0;
      fixedFrame.y = @fixedViewIndex == 0 ? 0.0 : flyingFrame.height + w
      fixedFrame.height = frame.height - w if fixedFrame.height > frame.height - w
    end

    fixedView.setFrame(fixedFrame)
    flyingView.setFrame(flyingFrame)
    self.setNeedsDisplay(true)
    self.window.invalidateCursorRectsForView(self) if self.window
  end

  private
  
  def updatePosition
    frame = self.subviews.objectAtIndex(@fixedViewIndex).frame
    @position = self.vertical? ? frame.width : frame.height
  end
end
