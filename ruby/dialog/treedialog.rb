# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'dialoghelper'

class TreeDialog < OSX::NSObject
  include OSX
  include DialogHelper  
  attr_accessor :delegate, :prefix
  ib_outlet :window, :tree
  
  TREE_ITEM_TYPE = 'item'
  TREE_ITEM_TYPES = [TREE_ITEM_TYPE]
  
  def initialize
    @prefix = 'treeDialog'
  end
  
  def start(conf)
    @w = ModelTreeItem.config_to_item(conf)
    @c = @w.units
    NSBundle.loadNibNamed_owner('TreeDialog', self)
    reload_tree
    @c.each {|i| @tree.expandItem(i) }
  	@tree.registerForDraggedTypes(TREE_ITEM_TYPES);
    update
    show
  end
  
  def show
    @window.center unless @window.isVisible
    @window.makeKeyAndOrderFront(self)
  end
  
  def close
    @delegate = nil
    @window.close
  end
  
  def reload_tree
    @tree.reloadData
  end
  
  def windowWillClose(sender)
    @tree.unregisterDraggedTypes
    fire_event('onClose')
  end
  
  def onOk(sender)
    @w.units = @c
    fire_event('onOk', ModelTreeItem.item_to_config(@w))
    @window.close
  end
  
  def onCancel(sender)
    @window.close
  end
  
  def onUp(sender)
    sel = current_sel
    return unless sel
    if sel.kind_of?(UnitTreeItem)
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
    if sel.kind_of?(UnitTreeItem)
      i = @c.index(sel)
      if i && i < @c.size - 1
        @c.delete_at(i)
        @c.insert(i+1, sel)
      end
    else
      u = sel.owner
      i = u.channels.index(sel)
      if i && i < u.channels.size - 1
        u.channels.delete_at(i)
        u.channels.insert(i+1, sel)
      end
    end
    reload_tree
    set_sel(sel)
    update
  end
  
  def outlineView_numberOfChildrenOfItem(sender, item)
    case item
      when nil; @c.size
      when UnitTreeItem; item.channels.size
      else 0
    end
  end
  
  def outlineView_isItemExpandable(sender, item)
    case item
      when nil; true
      when UnitTreeItem; item.channels.size > 0
      else false
    end
  end
  
  def outlineView_child_ofItem(sender, index, item)
    case item
      when nil; @c[index]
      when UnitTreeItem; item.channels[index]
      else nil
    end
  end
  
  def outlineView_objectValueForTableColumn_byItem(sender, column, item)
    item.label
  end
  
  def outlineView_shouldEditTableColumn_item(sender, column, item)
    false
  end
  
  def outlineViewSelectionDidChange(n)
    update
  end
  
  def outlineView_writeItems_toPasteboard(sender, items, pboard)
    i = items.to_a[0]
    if i.kind_of?(UnitTreeItem)
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
    
    if i.kind_of?(UnitTreeItem)
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
  
  def outlineView_acceptDrop_item_childIndex(sender, info, item, index)
    return false if index < 0
  	pboard = info.draggingPasteboard
  	return false unless pboard.availableTypeFromArray(TREE_ITEM_TYPES)
    target = pboard.propertyListForType(TREE_ITEM_TYPE)
    return false unless target
    i = find_item_from_pboard(target.to_s)
    return false unless i
    
    if i.kind_of?(UnitTreeItem)
      return false if item
      sel = current_sel
      
      ary = @c
      low = ary[0...index] || []
      high = ary[index...ary.size] || []
      low.delete(i)
      high.delete(i)
      @c = low + [i] + high
      reload_tree
      
      set_sel(sel)
    else
      return false unless item
      return false if item != i.owner
      sel = current_sel
      
      ary = item.channels
      low = ary[0...index] || []
      high = ary[index...ary.size] || []
      low.delete(i)
      high.delete(i)
      item.channels = low + [i] + high
      reload_tree
      
      set_sel(sel)
    end
    update
    true
  end
  
  def update
  end
end
