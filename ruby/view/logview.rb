# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class ALogView < WebView
  attr_accessor :keyDelegate, :resizeDelegate
  
  def keyDown(e)
    @keyDelegate.logViewKeyDown(e) if @keyDelegate
  end
  
  def setFrame(rect)
    @resizeDelegate.logViewWillResize(rect) if @resizeDelegate
    super_setFrame(rect)
    @resizeDelegate.logViewDidResize(rect) if @resizeDelegate
  end
  
  objc_method :maintainsInactiveSelection, 'c@:'
  def maintainsInactiveSelection
    true
  end
  
  def clearSel
    setSelectedDOMRange_affinity(nil, OSX::NSSelectionAffinityDownstream)
  end
  
  def selection
    sel = selectedDOMRange.cloneContents
    return nil unless sel
    iter = selectedFrame.DOMDocument.createNodeIterator_whatToShow_filter_expandEntityReferences(sel, OSX::DOM_SHOW_TEXT, nil, true)
    s = ''
    while node = iter.nextNode
      s << node.nodeValue
    end
    s.empty? ? nil : s
  end
end
