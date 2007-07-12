# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class TreeDialog < OSX::NSObject
  include OSX
  include DialogHelper  
  attr_accessor :delegate, :prefix
  ib_outlet :window, :tree, :upButton, :downButton
  
  def initialize
    @prefix = 'treeDialog'
  end
  
  def start(conf)
    @c = conf
    @c.each {|u| u.channels.each {|c| c.owner = u }}
    NSBundle.loadNibNamed_owner('TreeDialog', self)
    reload_tree
    @c.each {|i| @tree.expandItem(i) }
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
    sel = @tree.selectedRows
    return if sel.empty?
    sel = @tree.itemAtRow(sel[0])
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
    @tree.select(@tree.rowForItem(sel))
  end
  
  def onDown(sender)
    sel = @tree.selectedRows
    return if sel.empty?
    sel = @tree.itemAtRow(sel[0])
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
    @tree.select(@tree.rowForItem(sel))
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
  
  objc_method :outlineView_shouldEditTableColumn_item, 'c@:@@@'
  def outlineView_shouldEditTableColumn_item(sender, column, item)
    false
  end
  
  def outlineViewSelectionDidChange(n)
    update
  end
  
  def update
    sel = @tree.selectedRows
    if sel.empty?
      @upButton.setEnabled(false)
      @downButton.setEnabled(false)
      return
    else
      sel = @tree.itemAtRow(sel[0])
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
