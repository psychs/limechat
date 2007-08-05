# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class TreeView < OSX::NSOutlineView
  include OSX
  attr_accessor :key_delegate
  
  def countSelectedRows
    selectedRowIndexes.count.to_i
  end

  def selectedRows
    ary = []
    set = selectedRowIndexes
    unless OSX::NSIndexSet === set
      p set
      puts set.className.to_s
      raise 'Different Class'
    end
    i = set.firstIndex.to_i
    return ary if i == NSNotFound
    ary << i
    (set.count.to_i-1).times do
      i = set.indexGreaterThanIndex(i).to_i
      break if i == NSNotFound
      ary << i
    end
    ary
  end
  
  def select(index, scroll=true)
    selectRowIndexes_byExtendingSelection(NSIndexSet.indexSetWithIndex(index), false)
    scrollRowToVisible(index) if scroll
  end
  
  def menuForEvent(event)
    p = convertPoint_fromView(event.locationInWindow, nil)
    i = rowAtPoint(p)
    if i >= 0
      select(i)
    end
    menu
  end

  def keyDown(e)
    if @key_delegate
      case e.keyCode
      when 123..126 # cursor keys
      when 116,121  # page up/down
      else
        if @key_delegate.respond_to?(:treeView_keyDown)
          @key_delegate.treeView_keyDown(e)
          return
        end
      end
    end
    super_keyDown(e)
  end
end
