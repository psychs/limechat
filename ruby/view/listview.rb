# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class ListView < OSX::NSTableView
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
    scrollRowToVisible(index)
  end
  
  def selectRows(indices, extendSelection=false)
    set = NSMutableIndexSet.alloc.init
    indices.each {|i| set.addIndex(i) }
    selectRowIndexes_byExtendingSelection(set, extendSelection)
  end
  
  def rightMouseDown(event)
    p = convertPoint_fromView(event.locationInWindow, nil)
    i = rowAtPoint(p)
    if i >= 0
      unless selectedRowIndexes.containsIndex(i)
        select(i)
      end
    else
      #deselectAll(self)
    end
    super_rightMouseDown(event)
  end
  
  def keyDown(e)
    if @key_delegate
      case e.keyCode
      when 51,117
        if @key_delegate.respond_to?(:listView_delete)
          sel = selectedRows[0]
          if sel
            @key_delegate.listView_delete(self)
            return
          end
        end
      when 126
        if @key_delegate.respond_to?(:listView_moveUp)
          sel = selectedRows[0]
          if sel && sel == 0
            @key_delegate.listView_moveUp(self)
            return
          end
        end
      when 123..125 # cursor keys
      when 116,121  # page up/down
      else
        if @key_delegate.respond_to?(:listView_keyDown)
          @key_delegate.listView_keyDown(e)
          return
        end
      end
    end
    super_keyDown(e)
  end
end
