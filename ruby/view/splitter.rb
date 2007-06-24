class Splitter < OSX::NSSplitView
  include OSX
  attr_reader :fixedViewIndex, :position, :dividerThickness
  
  def initialize
    @position = 0
    @fixedViewIndex = 0
    @dividerThickness = 1
    @inverted = false
  end
  
  def awakeFromNib
    @dividerThickness = isVertical? ? 1 : 5
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
    @fixedViewIndex = @fixedViewIndex ? 0 : 1 if inverted?
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
  
  def drawDividerInRect(rect)
    if vertical?
      NSColor.colorWithCalibratedWhite_alpha(0.65, 1).set
      NSRectFill(rect);
    else
      NSColor.colorWithCalibratedWhite_alpha(0.65, 1).set
      sp = rect.origin.dup
      ep = sp.dup
      ep.x += NSWidth(rect)
      NSBezierPath.strokeLineFromPoint_toPoint(sp, ep)
      sp = rect.origin.dup
      sp.y += NSHeight(rect)
      ep = sp.dup
      ep.x += NSWidth(rect)
      NSBezierPath.strokeLineFromPoint_toPoint(sp, ep)
    end
  end
  
  def mouseDown(e)
    super_mouseDown(e)
    updatePosition
  end
  
  def splitView_constrainMinCoordinate_ofSubviewAt(sender, proposedMin, offset)
    if vertical?
      return 30.0 if offset == 0
    end
    proposedMin
  end
  
  def resizeSubviewsWithOldSize(oldSize)
    adjustSubviews
  end
  
  def adjustSubviews
    if self.subviews.count != 2
      super_adjustSubviews
      return
    end
    
    w = @dividerThickness
    fixedView = self.subviews.objectAtIndex(@fixedViewIndex)
    flyingView = self.subviews.objectAtIndex(@fixedViewIndex == 0 ? 1 : 0)
    fixedFrame = fixedView.frame
    flyingFrame = flyingView.frame
    
    if vertical?
      flyingFrame.size.width = NSWidth(frame) - w - @position
      flyingFrame.size.height = NSHeight(frame)
      flyingFrame.origin.x = @fixedViewIndex == 0 ? @position + w : 0.0
      flyingFrame.origin.y = 0.0
      flyingFrame.size.width = 0.0 if flyingFrame.size.width < 0.0
      fixedFrame.size.width = @position
      fixedFrame.size.height = NSHeight(frame)
      fixedFrame.size.width = @position
      fixedFrame.size.height = NSHeight(frame)
      fixedFrame.origin.x = @fixedViewIndex == 0 ? 0.0 : NSWidth(flyingFrame) + w
      fixedFrame.origin.y = 0.0
      fixedFrame.size.width = NSWidth(frame) - w if fixedFrame.size.width > NSWidth(frame) - w
    else
      flyingFrame.size.width = NSWidth(frame)
      flyingFrame.size.height = NSHeight(frame) - w - @position
      flyingFrame.origin.x = 0.0;
      flyingFrame.origin.y = @fixedViewIndex == 0 ? @position + w : 0.0;
      flyingFrame.size.height = 0.0 if flyingFrame.size.height < 0.0
      fixedFrame.size.width = NSWidth(frame);
      fixedFrame.size.height = @position;
      fixedFrame.origin.x = 0.0;
      fixedFrame.origin.y = @fixedViewIndex == 0 ? 0.0 : NSHeight(flyingFrame) + w
      fixedFrame.size.height = NSHeight(frame) - w if fixedFrame.size.height > NSHeight(frame) - w
    end
    
    flyingView.setFrame(flyingFrame)
    fixedView.setFrame(fixedFrame)
    self.setNeedsDisplay(true)
    self.window.invalidateCursorRectsForView(self) if self.window
  end

  private
  
  def updatePosition
    frame = self.subviews.objectAtIndex(@fixedViewIndex).frame
    @position = self.vertical? ? NSWidth(frame) : NSHeight(frame)
  end
end
