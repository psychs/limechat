# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class MarkedScroller < NSScroller
  attr_accessor :dataSource
  
  def drawRect(frame)
    super_drawRect(frame)
    return unless @dataSource
    ary = @dataSource.scroller_markedPosition(self)
    return if ary.empty?
    
    # prepare transform
  	transform = NSAffineTransform.transform
  	width = self.oc_class.scrollerWidthForControlSize(self.controlSize)
  	scale = self.scaleToContentView
  	transform.scaleXBy_yBy(1.0, scale)
  	offset = self.rectForPart(NSScrollerKnobSlot).y
  	transform.translateXBy_yBy(0.0, offset)
  	
  	# make lines
  	knobRect = self.rectForPart(NSScrollerKnob)
  	lines = []
  	prev = nil
  	ary.each do |i|
    	pt = NSPoint.new(0, i)
    	pt = transform.transformPoint(pt)
    	pt.x = pt.x.ceil
    	pt.y = pt.y.ceil + 0.5
    	next if pt == prev
    	prev = pt
    	line = NSBezierPath.bezierPath
    	line.setLineWidth(1.0)
		  line.moveToPoint(pt)
		  line.relativeLineToPoint(NSPoint.new(width, 0))
		  lines << line
		end
    
    # draw lines
  	NSRectClip(self.rectForPart(NSScrollerKnobSlot).inset(3.0, 4.0))
		@dataSource.scroller_markColor(self).set
		lines.each {|i| i.stroke }
		self.drawKnob
  end
  
  def scaleToContentView
  	self.rectForPart(NSScrollerKnobSlot).height / self.superview.contentView.documentRect.height;
  end
end
