# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class TreeDialog < OSX::NSObject
  include OSX
  include DialogHelper  
  attr_accessor :delegate, :prefix
  ib_outlet :window, :tree, :upButton, :downButton
  
  TREE_ITEM_TYPE = 'item'
  TREE_ITEM_TYPES = [TREE_ITEM_TYPE]
  
  def initialize
    @prefix = 'treeDialog'
  end
  
  def start(conf)
    @c = conf
    @c.each {|u| u.channels.each {|c| c.owner = u }}
    NSBundle.loadNibNamed_owner('TreeDialog', self)
    reload_tree
    @c.each {|i| @tree.expandItem(i) }
  	@tree.registerForDraggedTypes(TREE_ITEM_TYPES);
    update
    show
  end
  
  def show
    @window.makeKeyAndOrderFront(self)
  end
  
  def reload_tree
    @tree.reloadData
  end
  
  def windowWillClose(sender)
    @tree.unregisterDraggedTypes
    fire_event('onClose')
  end
  
  def onOk(sender)
    @c.each {|u| u.channels.each {|c| c.owner = nil }}
    fire_event('onOk', @c)
    @window.close
  end
  
  def onCancel(sender)
    @window.close
  end
  
  def onUp(sender)
    sel = current_sel
    return unless sel
    if sel.kind_of?(IRCUnitConfig)
      i = @c.index(sel)
      if i && i > 0
        @c.delete_at(i)
        @c.insert(i-1, sel)
      end
    else
      u = sel.owner
      i = u.channels.index(sel)
      if i && i > 0
        u.channels.delete_at(i)
        u.channels.insert(i-1, sel)
      end
    end
    reload_tree
    set_sel(sel)
    update
  end
  
  def onDown(sender)
    sel = current_sel
    return unless sel
    if sel.kind_of?(IRCUnitConfig)
      i = @c.index(sel)
      if i && i < @c.length - 1
        @c.delete_at(i)
        @c.insert(i+1, sel)
      end
    else
      u = sel.owner
      i = u.channels.index(sel)
      if i && i < u.channels.length - 1
        u.channels.delete_at(i)
        u.channels.insert(i+1, sel)
      end
    end
    reload_tree
    set_sel(sel)
    update
  end
  
  def outlineView_numberOfChildrenOfItem(sender, item)
    return @c.length unless item
    if item.kind_of?(IRCUnitConfig)
      item.channels.length
    else
      0
    end
  end
  
  objc_method :outlineView_isItemExpandable, 'c@:@@'
  def outlineView_isItemExpandable(sender, item)
    if item.kind_of?(IRCUnitConfig)
      item.channels.length > 0
    else
      false
    end
  end
  
  def outlineView_child_ofItem(sender, index, item)
    unless item
      @c[index]
    else
      item.channels[index]
    end
  end
  
  def outlineView_objectValueForTableColumn_byItem(sender, column, item)
    item.name
  end
  
  #objc_method :outlineView_shouldEditTableColumn_item, 'c@:@@@'
  def outlineView_shouldEditTableColumn_item(sender, column, item)
    false
  end
  
  def outlineViewSelectionDidChange(n)
    update
  end
  
  #objc_method :outlineView_writeItems_toPasteboard, 'c@:@@@'
  def outlineView_writeItems_toPasteboard(sender, items, pboard)
    i = items.to_a[0]
    if i.kind_of?(IRCUnitConfig)
      unit_index = @c.index(i)
      s = "#{unit_index}"
    else
      unit_index = @c.index(i.owner)
      channel_index = i.owner.channels.index(i)
      s = "#{unit_index}-#{channel_index}"
    end
    pboard.declareTypes_owner(TREE_ITEM_TYPES, self)
    pboard.setPropertyList_forType(s, TREE_ITEM_TYPE)
    true
  end
  
  def find_item_from_pboard(s)
    if /^(\d+)-(\d+)$/ =~ s
      u = $1.to_i
      c = $2.to_i
      @c[u].channels[c]
    elsif /^(\d)+$/ =~ s
      @c[s.to_i]
    else
      nil
    end
  end
  
  def outlineView_validateDrop_proposedItem_proposedChildIndex(sender, info, item, index)
    return NSDragOperationNone if index < 0
  	pboard = info.draggingPasteboard
  	return NSDragOperationNone unless pboard.availableTypeFromArray(TREE_ITEM_TYPES)
    target = pboard.propertyListForType(TREE_ITEM_TYPE)
    return NSDragOperationNone unless target
    i = find_item_from_pboard(target.to_s)
    return NSDragOperationNone unless i
    if i.kind_of?(IRCUnitConfig)
      return NSDragOperationNone if item
    else
      return NSDragOperationNone unless item
      return NSDragOperationNone if item != i.owner
    end
    NSDragOperationGeneric
  end
  
  def current_sel
    sel = @tree.selectedRows
    sel.empty? ? nil : @tree.itemAtRow(sel[0])
  end
  
  def set_sel(item)
    return unless item
    index = @tree.rowForItem(item)
    @tree.select(index) if index >= 0
  end
  
  objc_method :outlineView_acceptDrop_item_childIndex, 'c@:@@@i'
  def outlineView_acceptDrop_item_childIndex(sender, info, item, index)
    return false if index < 0
  	pboard = info.draggingPasteboard
  	return false unless pboard.availableTypeFromArray(TREE_ITEM_TYPES)
    target = pboard.propertyListForType(TREE_ITEM_TYPE)
    return false unless target
    i = find_item_from_pboard(target.to_s)
    return false unless i
    if i.kind_of?(IRCUnitConfig)
      return false if item
      sel = current_sel
      
      ary = @c
      high = ary[0...index] || []
      low = ary[index...ary.length] || []
      high.delete(i)
      low.delete(i)
      @c = high + [i] + low
      reload_tree
      
      set_sel(sel)
    else
      return false unless item
      return false if item != i.owner
      sel = current_sel
      
      ary = item.channels
      high = ary[0...index] || []
      low = ary[index...ary.length] || []
      high.delete(i)
      low.delete(i)
      item.channels = high + [i] + low
      reload_tree
      
      set_sel(sel)
    end
    update
    true
  end
  
  def update
    sel = current_sel
    unless sel
      @upButton.setEnabled(false)
      @downButton.setEnabled(false)
    else
      if sel.kind_of?(IRCUnitConfig)
        i = @c.index(sel)
        if i
          @upButton.setEnabled(i > 0)
          @downButton.setEnabled(i != @c.length - 1)
        else
          @upButton.setEnabled(false)
          @downButton.setEnabled(false)
        end
      else
        u = sel.owner
        i = u.channels.index(sel)
        if i
          @upButton.setEnabled(i > 0)
          @downButton.setEnabled(i != u.channels.length - 1)
        else
          @upButton.setEnabled(false)
          @downButton.setEnabled(false)
        end
      end
    end
  end
end
