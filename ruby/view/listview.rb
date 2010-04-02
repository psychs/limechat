# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class AListView < NSTableView
  attr_accessor :keyDelegate, :textDelegate
  
  def countSelectedRows
    selectedRowIndexes.count.to_i
  end

  def selectedRows
    selectedRowIndexes.to_a
  end
  
  def select(index, scroll=true)
    selectRowIndexes_byExtendingSelection([index].to_indexset, false)
    scrollRowToVisible(index)
  end
  
  def selectRows(indices, extendSelection=false)
    selectRowIndexes_byExtendingSelection(indices.to_indexset, extendSelection)
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
  
  def setFont(font)
    tableColumns.to_a.each {|i| i.dataCell.setFont(font)}
    f = frame
    f.height = 1e+37
    f.height = tableColumns.to_a[0].dataCell.cellSizeForBounds(f).height.ceil
    setRowHeight(f.height)
    setNeedsDisplay(true)
  end
  
  def font
    tableColumns.to_a[0].dataCell.font
  end
  
  def keyDown(e)
    if @keyDelegate
      case e.keyCode
      when 51,117
        if @keyDelegate.respond_to?(:listViewDelete)
          sel = selectedRows[0]
          if sel
            @keyDelegate.listViewDelete(self)
            return
          end
        end
      when 126
        if @keyDelegate.respond_to?(:listViewMoveUp)
          sel = selectedRows[0]
          if sel && sel == 0
            @keyDelegate.listViewMoveUp(self)
            return
          end
        end
      when 123..125 # cursor keys
      when 116,121  # page up/down
      else
        if @keyDelegate.respond_to?(:listViewKeyDown)
          @keyDelegate.listViewKeyDown(e)
          return
        end
      end
    end
    super_keyDown(e)
  end
  
  def textDidEndEditing(note)
    if @textDelegate
      @textDelegate.textDidEndEditing(note)
    end
  end
end
